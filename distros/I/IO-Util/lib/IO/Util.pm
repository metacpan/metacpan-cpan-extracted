package IO::Util ;
$VERSION = 1.5 ;
use 5.006_001 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; $Carp::Internal{+__PACKAGE__}++ 
; use File::Spec

############# slurping files #############

; sub slurp
   { my %a = map {ref||path => $_} @_
   ; local $_ = defined $a{path}    ? $a{path}
              : defined $a{GLOB}    ? $a{GLOB}
              : (defined && length) ? $_
              : croak 'Wrong file argument, died'
   ; $a{SCALAR} ||= \ my $content
   ; if (  ref     eq 'GLOB'
        || ref \$_ eq 'GLOB'
        )
      { ${$a{SCALAR}} = do { local $/; <$_> }
      }
     else
      { open _ or croak "$^E, died"
      ; ${$a{SCALAR}} = do { local $/; <_> }
      ; close _
      }
   ; $a{SCALAR}
   }


############# unique ids #############

; my %charset = ( base34 => [ 1..9, 'A'..'N', 'P'..'Z' ]
                , base62 => [ 0..9, 'a'..'z', 'A'..'Z' ]
                )
; my $separator = '_'

; sub import
   { return unless @_
   ; require Exporter
   ; our @ISA = 'Exporter'
   ; our @EXPORT_OK = qw| capture
                          slurp
                          Tid Lid Uid
                          load_mml
                        |
   ; my ($pkg, @subs) = @_
   ; require Time::HiRes   if grep /id$/  , @subs
   ; require Sys::Hostname if grep /^Uid$/, @subs
   ; $pkg->export_to_level(1, @_)
   }
 
; sub _convert
   { my ( $num, $args ) = @_
   ; my $chars = defined $$args{chars}
                 ? ref($$args{chars}) eq 'ARRAY'
                   ? $$args{chars}
                   : exists $charset{$$args{chars}}
                     ? $charset{$$args{chars}}
                     : croak 'Invalid chars, died'
                 : $charset{base34}
   ; my $result = ''
   ; my $dnum = @$chars
   ; while ( $num > 0 )
      { substr($result, 0, 0) = $$chars[ $num % $dnum]
      ; $num = int($num/$dnum)
      }
   ; $result
   }

; sub Tid
   { require Time::HiRes
   ; my %args = @_
   ; my $sep = defined $args{separator} ? $args{separator} : $separator
   ; my($sec, $usec) = Time::HiRes::gettimeofday()
   ; my($new_sec, $new_usec)
   ; do{ ($new_sec, $new_usec) = Time::HiRes::gettimeofday() }
       until ( $new_usec != $usec || $new_sec != $sec )
   ; join $sep, map _convert($_, \%args), $sec , $usec
   }
   
; sub Lid
   { my %args = @_
   ; my $sep = defined $args{separator} ? $args{separator} : $separator
   ; join $sep, _convert($$, \%args), Tid(@_)
   }

; sub Uid
   { require Sys::Hostname
   ; my %args = @_
   ; my $sep = defined $args{separator} ? $args{separator} : $separator
   ; my $ip = sprintf '1%03d%03d%03d%03d'
            , $args{IP}
              ? @{$args{IP}}
              : unpack( "C4", (gethostbyname(Sys::Hostname::hostname()))[4] )
   ; join $sep, _convert($ip, \%args), Lid(@_)
   }

############# parsing cache #############

; our %PARSING_CACHE

; sub _path_mtime
   { my $path  = File::Spec->rel2abs($_[0])
   ; my $mtime = ( stat($path) )[9] or croak "$^E, died"
   ; $path, $mtime
   }

; sub _set_parsing_cache
   { my $type = shift
   ; my ($path, $mtime) = &_path_mtime
   ; $PARSING_CACHE{$type}{$path}{mtime} = $mtime
   ; $PARSING_CACHE{$type}{$path}{value} = $_[1]
   }
   
; sub _get_parsing_cache
   { my $type = shift
   ; my ($path, $mtime) = &_path_mtime
   ; exists $PARSING_CACHE{$type}{$path}               # if it is cached
     &&! $mtime > $PARSING_CACHE{$type}{$path}{mtime}  # and not old
     ? $PARSING_CACHE{$type}{$path}{value}
     : undef
   }

; sub _purge_parsing_cache
   { my $type = shift
   ; @_ || return delete $PARSING_CACHE{$type}
   ; map delete $PARSING_CACHE{$type}{$_}
   , map File::Spec->rel2abs($_)
   , @_
   }

############# loading MML #############


; my %parser_re = ( '<>' =>
                  qr/ \G(.*?)   # elements and text outside blocks
                      (?<!\\)<  # not excaped '<'
                        (\w+)([^>]*?)  # id + attributes
                      (?<!\\)>  # not escaped '>'
                      (.*?)     # content
                      <\/\2>    # end
                    /xs
                  , '[]' =>
                  qr/ \G(.*?)   # elements and text outside blocks
                      (?<!\\)\[  # not excaped '['
                        (\w+)([^\]]*?)  # id + attributes
                      (?<!\\)\]  # not escaped ']'
                      (.*?)     # content
                      \[\/\2\]    # end
                    /xs
                  , '{}' =>
                  qr/ \G(.*?)   # elements and text outside blocks
                      (?<!\\)\{  # not excaped '<'
                        (\w+)([^\}]*?)  # id + attributes
                      (?<!\\)\}  # not escaped '>'
                      (.*?)     # content
                      \{\/\2\}    # end
                    /xs
                  )
                  
; my %not_escaped_re = ( '<>' => qr/( (?<!\\) < | (?<!\\) > )/xs
                       , '[]' => qr/( (?<!\\) \[ | (?<!\\) \] )/xs
                       , '{}' => qr/( (?<!\\) \{ | (?<!\\) \} )/xs
                       )
                       
; my %comment_re = ( '<>' => qr/<!--.*?-->/xs
                   , '[]' => qr/\[!--.*?--\]/xs
                   , '{}' => qr/\{!--.*?--\}/xs
                   )
   
; sub load_mml
   { my $mml = shift
   ; my $opt = ref $_[0] eq 'HASH' ? $_[0] : { @_ }
   ; if ( $$opt{optional} && not ref $mml )
      { return unless -f $mml
      }
   ; my $struct
   ; defined $$opt{cache} or $$opt{cache} = 1
   ; if ( $$opt{cache} && not ref $mml )
      { $struct = _get_parsing_cache 'mml_struct', $mml
      ; return $struct if $struct
      }
   ; defined $$opt{strict} or $$opt{strict} = 1
   ; my $content = ref $mml eq 'SCALAR' ? $mml : slurp $mml
   ; $$opt{markers} ||= '<>'
   ; $$content =~ s/$comment_re{$$opt{markers}}//g
   ; $struct = parse_mml( '', $content, $opt )
   ; unless ( $$opt{keep_root} )
      { ref $struct eq 'HASH'
        or croak 'Parsed structure is not a HASH reference: '
               . 'check your MML or set keep_root, died'
      ; $struct = $$struct{(keys %$struct)[0]}
      }
   ; $$opt{cache} &&! ref($mml)
     && _set_parsing_cache 'mml_struct', $mml, $struct
   ; $struct
   }
   
; sub parse_mml
   { my ($id, $mml, $opt) = @_
   ; my ($node, $control, $no_data)
   ; while ( $$mml =~ /$parser_re{$$opt{markers}}/g )
      { $no_data = 1
      ; my ( $garb, $child_id, $attr, $child_mml ) = ($1, $2, $3, $4)
      ; if ( $$opt{strict} )
         { $garb =~ /\S/ && croak
           "Garbage '$garb' found parsing element '$child_id', died"
         ; length $attr && croak
           "Attributes '$attr' found parsing element '$child_id', died"
         }
      ; my ($k) = grep $child_id =~ /$_/
                , keys %{$$opt{handler}}
      ; my $parser_sub = defined $k
                         ? $$opt{handler}{$k}
                         : \&parse_mml
      ; my $child = do{ no strict 'refs'
                      ; &$parser_sub($child_id, \$child_mml, $opt)
                      }
      ; if ( defined $child )
         { if ( defined $$control{$child_id} )
            { if ( $$control{$child_id} > 1 )
               { push @{$$node{$child_id}}, $child
               }
              else
               { $$node{$child_id} = [ $$node{$child_id}, $child ]
               }
            }
           else
            { $$node{$child_id} = $child
            }
         ; $$control{$child_id} ++
         }
      }
   ; return $node if $no_data
   ; $$opt{strict} && ( $$mml =~ $not_escaped_re{$$opt{markers}} )
	  and croak "Not escaped '$1' found in '$id' data, died"
	; $$mml =~ s/\\(.)/$1/g   # unescape
	; my ($k) = grep $id =~ /$_/
	          , keys %{$$opt{filter}}
   ; my $filter_sub = $$opt{filter}{$k} if defined $k
   ; $filter_sub
     ? do{ local $_ = $$mml
         ; no strict 'refs'
         ; &{$filter_sub}($id, $mml, $opt)
         }
     : $$mml
   }

; sub TRIM_BLANKS  # filter
   { s/^\s+//gm
   ; s/\s+$//gm
   ; $_
   }

; sub ONE_LINE    # filter
   { s/\n+/ /g
   ; $_
   }

; sub SPLIT_LINES  # handler
   { [ split /\n+/, parse_mml @_ ]
   }

############## capturing output #############

; sub capture (&;@)
   { my %a = map {ref, $_} @_
   ; $a{GLOB} ||= select
   ; local $IO::Util::WriteHandle::out_ref
     = $a{SCALAR} || \ my $scalar
   ; no strict 'refs'
   ; if ( my $tied = tied *{$a{GLOB}} )
      { my $tied_class = ref $tied
      ; bless $tied, 'IO::Util::WriteHandle'
      ; $a{CODE}->()
      ; bless $tied, $tied_class
      }
     else
      { tie *{$a{GLOB}}, 'IO::Util::WriteHandle'
      ; $a{CODE}->()
      ; untie *{$a{GLOB}}
      }
   ; $IO::Util::WriteHandle::out_ref
   }


###############################
; package IO::Util::WriteHandle
; use strict
; our $out_ref

; sub TIEHANDLE
   { bless \ my $dummy, $_[0]
   }

; sub WRITE
   { shift
   ; my( $scalar, $len, $offset ) = @_
   ; my $data = substr $scalar
                     , $offset || 0
                     , $len    || length $scalar
   ; $$out_ref .= $data
   ; length $data
   }

; sub PRINT
   { shift
   ; $$out_ref .= join defined $, ? $, : '', @_
   ; $$out_ref .= $\ if defined $\
   ; 1
   }

; sub PRINTF
   { shift
   ; $$out_ref .= sprintf shift, @_
   ; 1
   }

; sub OPEN    { 1 }
; sub CLOSE   { 1 }
; sub FILENO  { 1 }
; sub BINMODE { 1 }
; sub UNTIE   { 1 }

###### not supported #######
; sub READ     { 0 }
; sub READLINE { undef }
; sub GETC     { undef }
; sub TELL     {-1 }
; sub SEEK     { 0 }
; sub EOF      { 1 }


; 1
__END__

=pod

=head1 NAME

IO::Util - A selection of general-utility IO function

=head1 VERSION 1.5

The latest versions changes are reported in the F<Changes> file in this distribution.

=head1 INSTALLATION

=over

=item Prerequisites

    Time::HiRes   = 0
    Sys::Hostname = 0

=item CPAN

    perl -MCPAN -e 'install IO::Util'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

  use IO::Util qw(capture slurp Tid Lid Uid load_mml);

capture()

  # captures the selected filehandle
  $output_ref = capture { any_printing_code() } ;
  # now $$output_ref eq 'something'
  
  # captures FILEHANDLE
  $output_ref = capture { any_special_printing_code() } \*FILEHEANDLER ;
  
  # append the output to $captured
  capture { any_printing_code() } \*FILEHEANDLER , \$captured
  # now $captured eq 'something'
  
  # use another class to tie the handler
  use IO::Scalar ;
  $IO::Util::TIE_HANDLE_CLASS = 'IO::Scalar'

slurp()

  $_ = '/path/to/file' ;
  $content_ref = slurp ;
  $content_ref = slurp '/path/to/file' ;
  $content_ref = slurp \*FILEHANDLE ;
  
  # append the file content to $content
  $_ = '/path/to/file' ;
  slurp \$content;
  slurp '/path/to/file', \$content ;
  slurp \*FILEHANDLE, \$content ;


Tid(), Lid(), Uid()

  $temporarily_unique_id = Tid ; # 'Q9MU1N_NVRM'
  $locally_unique_id     = Lid ; # '2MS_Q9MU1N_P5F6'
  $universally_unique_id = Uid ; # 'MGJFSBTK_2MS_Q9MU1N_PWES'

A MML file (Minimal Markup Language)

   <opt>
    <!-- a multi line
     comment-->
       <parA>
           <optA>01</optA>
           <optA>02</optA>
           <optA>03</optA>
       </parA>
       <parB>
           <optA>04</optA>
           <optA>05</optA>
           <optA>06</optA>
           <optB>
              <key>any key</key>
           </optB>
       </parB>
   </opt>

load_mml()

  $struct = load_mml 'path/to/mml_file' ;
  $struct = load_mml \ $mml_string ;
  $struct = load_mml \ *MMLFILE ;
  $struct = load_mml ..., %options ;

  # $struct = {
  #             'parA' => {
  #                         'optA' => [
  #                                     '01',
  #                                     '02',
  #                                     '03'
  #                                   ]
  #                       },
  #             'parB' => {
  #                         'optA' => [
  #                                     '04',
  #                                     '05',
  #                                     '06'
  #                                   ],
  #                         'optB' => {
  #                                     'key' => 'any key'
  #                                   }
  #                      }
  #           }

=head1 DESCRIPTION

This is a micro-weight module that exports a few functions of general utility in IO operations.

=head1 CAPTURING OUTPUT

=head2 capture { code } [ arguments ]

Use this function in order to capture the output that a I<code> write to any I<FILEHANDLE> (usually STDOUT) by using C<print>, C<printf> and C<syswrite> statements. The function works also with already tied handles, and older perl versions.

This function expects a mandatory code reference (usually a code block) passed as the first argument and two optional arguments: I<handle_ref> and I<scalar_ref>. The function executes the referenced code and returns a reference to the captured output.

If I<handle_ref> is omitted the selected filehandle will be used by default (usually C<STDOUT>). If you pass I<scalar_ref>, the output will be appended to the referenced scalar. In this case the result of the function will be the same SCALAR reference passed as the argument.

You can pass the optional arguments in mixed order. All the following statement work:

   $output_ref = capture {...}
   $output_ref = capture {...} \*FH
   capture {...} \*FH, \$output ; # capure FH and append to $output
   capture {...} \$output, \*FH ; # capure FH and append to $output
   capture {...} \$output ;       # append to $output
   capture \&code, ...            # a classical code ref works too

B<Note>: This function ties the I<FILEHANDLE> to IO::Util::WriteHandle class and unties it after the execution of the I<code>. If I<FILEHANDLE> is already tied to any other class, it just temporary re-bless the tied object to IO::Util::Handle class, re-blessing it again to its original class after the execution of the I<code>, thus preserving the original I<FILEHANDLE> configuration.

=head1 SLURPING FILES

=head2 slurp [ arguments ]

The C<slurp> function expects a path to a I<file> or an open I<handle_ref>, and returns the reference to the whole I<file|handle_ref> content. If no argument is passed it will use $_ as the argument.

As an alternative you can pass also a SCALAR reference as an argument, so the content will be appended to the referenced scalar. In this case the result of the function will be the same SCALAR reference passed as the argument.

B<Note>: You can pass the optional arguments in mixed order. All the following statement work:

   $content_ref = slurp ;   # open file in $_
   $content_ref = slurp '/path/to/file';
   slurp '/path/to/file', \$content ;
   slurp \$content, '/path/to/file' ;
   slurp \$content ;

=head1 GENERATING UNIQUE IDs

The C<Tid>, C<Lid> and C<Uid> functions return an unique ID string useful to name temporary files, or use for other purposes.

=head2 Tid ( [options] )

This function returns a temporary ID valid for the current process only. Different temporarily-unique strings are granted to be unique for the current process only ($$)

=head2 Lid ( [options] )

This function returns a local ID valid for the local host only. Different locally-unique strings are granted to be unique when generated by the same local host

=head2 Uid ( [options] )

This function returns an universal ID. Different universally-unique strings are granted to be unique also when generated by different hosts. Use this function if you have more than one machine generating the IDs for the same context. This function includes the host IP number in the id algorithm.

=head2 *id options

The above functions accept an optional hash of named arguments:

=over

=item chars

You can specify the set of characters used to generate the uniquid string. You have the following options:

=over

=item chars => 'base34'

uses [1..9, 'A'..'N', 'P'..'Z']. No lowercase chars, no number 0 no capital 'o'. Useful to avoid human mistakes when the id may be represented by non-electronical means (e.g. communicated by voice or read from paper). This is the default (used if you don't specify any chars option).

=item  chars => 'base62'

Uses C<[0..9, 'a'..'z', 'A'..'Z']>. This option tries to generate shorter ids.

=item chars => \@chars

Any reference to an array of arbitrary characters.


=back

=item separator

The character used to separate group of characters in the id. Default '_'.

=item IP

Applies to C<Uid> only. This option allows to pass the IP number used generating the universally-unique id. Use this option if you know what you are doing.

=back

   $ui = Tid                           # Q9MU1N_NVRM
   $ui = Lid                           # 2MS_Q9MU1N_P5F6
   $ui = Uid                           # MGJFSBTK_2MS_Q9MU1N_PWES
   $ui = Uid separator=>'-'            # MGJFSBTK-2DH-Q9MU6H-7Z1Y
   $ui = Tid chars=>'base62'           # 1czScD_2h0v
   $ui = Lid chars=>'base62'           # rq_1czScD_2jC1
   $ui = Uid chars=>'base62'           # jQaB98R_rq_1czScD_2rqA
   $ui = Lid chars=>[ 0..9, 'A'..'F']  # 9F4_41AF2B34_62E76

=head1 Minimal Markup Language (MML)

A lot of programmers use (I<de facto>) a subset of canonical XML which is characterized by:

 No Attributes
 No mixed Data and Element content
 No Processing Instructions (PI)
 No Document Type Declaration (DTD)
 No non-character entity-references
 No CDATA marked sections
 Support for only UTF-8 character encoding
 No optional features

That subset has no official standard, so in this description we will generically refer to it as 'Minimal Markup Language' or MML. Please, note that MML is just an unofficial and generic way to name that minimal XML subset, avoiding any possible MXML, SML, MinML, /.+ML$/ specificity.

=head2 MML advantages

If you need just to store configuration parameters and construct any perl data structure, MLM is all what you need. Using it instead full featured XML gives you a few very interesting advantages:

=over

=item *

it is really simple to use/edit and understand also by any unskilled people

=item  *

you can parse it with very lite, fast and simple RE, thus avoiding to load and execute several thousands of perl code needed to parse full featured XML

=item *

anyway any canonical XML parser will be able to parse it as well

=back

=head2 About XML parsing and structure reduction

The C<load_mml> function produces perl structures exactly like other CPAN modules (e.g. L<XML::Simple|XML::Simple>, L<XML::Smart|XML::Smart>) but use the opposite approach. That modules usually require a canonical XML parser to achieve a full XML tree, then prune all the unwanted branches. That means thousands of line of code loaded and executed, and a potentially big structure to reduce, which probably is a waste of resources when you have just to deal with simple MML.

The C<load_mml> uses just a few lines of recursive code, parsing MML with a simple RE. It builds up only the branches it needs, optionally ignoring all the unwanted nodes. That is exactly what you need for MML, but it is obviously completely inappropriate for full XML files (e.g. HTML) which use attributes and other features unsupported by MML.

=head2 load_mml ( MML [, options] )

This function parses the I<MML> eventually using the I<options>, and returns a perl structure reflecting the MML structure and any custom logic you may need (see L<"options">). It accepts one I<MML> parameter that can be a reference to a SCALAR content, a path to a file or a reference to a filehandle.

This function accepts also a few I<options> which could be passed as plain name=>value pairs or as a HASH reference.

=head3 options

You can customize the process by setting a few option, which will allow you to gain B<full control> over the process and the resulting structure (see also the F<t/05_load_mml.t> test file for a few examples):

=over

=item optional => 0|1

Boolean. This option applies when the MML argument is a path to a file: a true value will not try to load a file that doesn't exists; a false value will croak on error. False by default.

=item strict => 1|0

Boolean. A true value will croak when any unsupported syntax is found, while a false value will quitely ignore unsupported syntax. Default true (strict).

   $strict_mml = '<opt><a>01</a></opt>';
   $non_strict_mml = << 'EOS';
   <opt>
       mixed content ignored
       <elem attr="ignored">01</elem>
   </opt>'
   EOS
   
   $structA = load_mml \$non_strict_mml ; # would croak
   $structB = load_mml \$non_strict_mml, strict=>0 ;  # ok

=item cache => 1|0

Boolean. if I<MML> is a path, a true value will cache the mml structure in a global (persistent under mod_perl). C<load_mml> will open and parse the file only the first time or if the file has been modified. If for any reason you don't want to cache the structure or  set this option to a false value. Default true (cached).

B<Note>: If you need to parse the same file with different options, (thus producing different structures) you must disable the I<chache>. Also, when you have a lot of mml files with very simple structure the cache could slow down the parsing. Caching is convenient when you have complex or large structure and a few files.

=item markers => '<>'|'[]'|'{}'

Instead of using the canonical '<>' markers, you can use the C<[]> or the C<{}>non standard markers. Your file will not be XML compliant anymore, anyway it may be very useful when the file content is composed by XML or HTML chunks, since you can avoid the escaping of '<' and '>'. Default standard XML markers '<>'.

   $mml = '[opt][a]<a href="something">something</a>[/a][/opt]';
   $structA = load_mml \$mml, markers => '[]' ;
   # $structA = {
   #              'a' => '<a href="something">something</a>'
   #            };


=item keep_root => 0|1

Boolean. A true value will keep the root element, while a false value will strip the root. Default false (root stripped)

   $mml = '<opt><a>01</a></opt>';
   $structA = load_mml \$mml ;
   
   $$struct{a} eq '01'; # true
   
   # $structA = {
   #              'a' => '01'
   #            };
   
   $structB = load_mml \$mml, keep_root=>1 ;
   
   $$struct{opt}{a} eq '01'; # true
   
   # $structB = {
   #              'opt' => {
   #                         'a' => '01'
   #                       }
   #            };

=item filter => { id|re => CODE|'TRIM_BLANKS'|'ONE_LINE' }

This option allows to filter data from the MML to the structure. You must set it to an hash of id/filter. The key id can be the literal element id which content you want to filter, or any compiled RE you want to match against the id elements; the filter can be a CODE reference or the name of a couple of literal built-in filters: 'TRIM_BLANKS', 'ONE_LINE'.

The referenced code will receive I<id>, I<data_reference> and I<active_options_referece> as the arguments; besides for regexing convenience the data is aliased in C<$_>.

   $mml = << 'EOS';
   <opt>
      <foo>aaa</foo>
      <bar>bBB</bar>
      <baz>ZZz</baz>
      <multi_line>
        other
        data
      </multi_line>
      <other_stuff>something</other_stuff>
      <anything_else>not filtered</anything_else>
   </opt>
   EOS
   
   $struct = load_mml \$mml, filter=>{ foo         => sub{uc},
                                       qr/^b/      => sub{lc},
                                       multi_line  => 'TRIM_BLANKS',
                                       other_stuff => \&my_filter
                                     };
   
   sub my_filter {
       my ($id, $data_ref, $opt) = @_ ;
       # $_ contains the actual data
       # so you could use it instead of $$data_ref
       ....
       # return $_ (if modified it with any s///)
       # or any arbitrarily modified data
       return 'something else';
   }
       
   # $struct = {
   #             'foo' => 'AAA', # it was 'aaa'
   #             'bar' => 'bbb', # it was 'bBB'
   #             'baz' => 'zzz', # it was 'ZZz'
   #             'multi_line' => "other\ndata",  # it was "\n  other\n  data\n"
   #             'other_stuff' => 'something else', # it was 'something'
   #             'anything_else' => 'not filtered'  # the same
   #           }

=item handler => { id|re => CODE|'SPLIT_LINES' }

This option allows you to execute any code during the parsing of the MML in order to change the returned structure or do any other task. It allows you to implement your own syntax, checks and executions, skip any branch, change the options of any child node, generate nodes or even objects to add to the returned structure.

You must set it to an hash of id/handler. The key id can be the literal element id which content you want to handler, or any compiled RE you want to match against the id elements; the filter may be a CODE reference or the name of a literal built-in handler C<'SPLIT_LINES'> (an handler that splits the lines of the node into an array of elements: see the example below).

The referenced CODE will be called instead the standard C<IO::Util::parse_mml> handler, and will receive I<id>, I<data_reference> and I<active_options_referece> as the arguments.

It is expected to return the branch to add to the returned structure. If the referenced CODE needs to refers to the original branch structure, it could retrieve it by using IO::Util::parse_mml().

A few examples using this same MML string:

   $mml = << 'EOS';
   <opt>
     <a>
        <b>Foo</b>
        <b>Bar</b>
     </a>
     <c>something</c>
   </opt>
   EOS

Regular parsing and structure:

   $struct = load_mml \$mml # no options
   
   # $struct = {
   #             'a' => {
   #                      'b' => [
   #                               'Foo',
   #                               'Bar'
   #                             ]
   #                    },
   #             'c' => 'something'
   #           } ;

Skip all the 'a' elements:

   $struct = load_mml \$mml, handler=>{ a => sub{} } ; # just for 'a' elements
                     
   # $struct = { 'c' => 'something' } ;


Folding an array:

   $struct = load_mml \$mml, handler => { a => \&a_handler } ; # just for 'a'

     
   sub a_handler {
       # get the original branch
       my $branch = IO::Util::parse_mml( @_ );
       $$branch{b} # ['Foo','Bar']
   }
   
   # $structB = {
   #              'a' => [
   #                       'Foo',
   #                       'Bar'
   #                     ],
   #              'c' => 'something'
   #            } ;

You can also use the built-in handler 'SPLIT_LINES' and write a MML like this:

   $mml = << 'EOS';
   <opt>
     <a>
        <b>
        Foo
        Bar
        </b>
     </a>
     <c>something</c>
   </opt>
   EOS
   
   $struct = load_mml \$mml,
              handler=>{ b => 'SPLIT_LINES },
              filter =>{ b => 'TRIM_BLANKS' }
   
   # $struct = {
   #             'a' => {
   #                      'b' => [
   #                               'Foo',
   #                               'Bar'
   #                             ]
   #                    },
   #             'c' => 'something'
   #           } ;

=back

=head2 parse_mml (id, MML [, options])

Used internally and eventually by any handler, in order to parse any I<MML> chunk and return its branch structure. It requires the element I<id>, the reference to the I<MML> chunk, eventually accepting the options hash reference to use for the branch.

B<Note>: You can escape any character (specially < and >) by using the backslash '\'. XML comments can be added to the MML and will be ignored by the parser.

=head1 SUPPORT and FEEDBACK

If you need support or if you want just to send me some feedback or request, please use this link: http://perl.4pro.net/?IO::Util.

=head1 AUTHOR and COPYRIGHT

© 2004-2005 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
