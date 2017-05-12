=head1 NAME

Exporter::VA - Improved Exporter featuring Versioning and Aliasing.

=cut

### see the main POD at the end of this file.

package Exporter::VA;
use strict;
use warnings;
use Carp qw/croak carp/;
use utf8;
our $VERSION= v1.3.0.1;  # major.minor.update.docsonly
*VERBOSE= *STDERR{IO};   # can be redirected

my %EXPORT= (
   '&VERSION' => \&export_VERSION,
   '&import' => \&export_import,
   '&AUTOLOAD' => \&export_AUTOLOAD,
   '.default_VERSION'=> v0.1,
   ':normal' => [qw/ &VERSION &import &AUTOLOAD/ ],
   '.&begin' => \&begin,
   '&normalize_vstring' => \\&normalize_vstring,
   '&autoload_symbol' => \\&autoload_symbol,
   );

sub Err
 {
 # improve this to give proper level information to Croak.
 croak @_;
 }

sub Warn
 {
 carp @_;
 }

sub dump
 {
 # Currently implemented to use Data::Dumper, but might change to be more custom some day.
 eval {  require Data::Dumper };
 if ($@) {
    print VERBOSE "**(Exporter::VA::dump) ERROR: cannot load Data::Dumper module to support the dump() method or --dump pragma\n";
    return;
    }
 my $self= shift;
 print VERBOSE (Data::Dumper->Dump ( [ $self ], ["*EXPORT"]), $/);
 }

sub is_vstring($)
 {
 my $s= shift;
 my $count= $s =~ tr/\0-\1F//;
 return $count > 0;
 # to disambiguate a v-string like v65.66.67, add a trailing .0 becoming v.65.66.67.0 with same meaning.
 }

sub normalize_vstring ($)
 {
 my $v= shift;
 # for now, doesn't do much.
 return v0 if length ($v) eq 0;
 $v= pack ("U*", split (/\./,$v))
    unless is_vstring ($v);
 # remove trailing redundant zeros (but keep it at least 2 digits, so v1.0 is right, v1.0.0.0 is truncated)
 $v =~ s/(?<=..)\0+$//;
 return $v;
 }


sub _calling_client()
 {
 my $n= 1;
 for (;;) {
    my $caller= caller($n);
    return $caller  if $caller ne __PACKAGE__;  # I want the first caller of this module
    ++$n;
    }
 }

sub _check_allowed_versions
 {
 my ($version, $list)= @_;
 return unless defined $list;  # if .allowed_VERSIONS is not specified, anything is allowed.
 foreach (@$list) {
    return  if $version eq $_;  # normalized earlier.
    }
 # compose error message
 my $vs= join( ', ', map { _format_vstring($_)} (@$list) );
 Err "(Exporter::VA) you asked for ", _format_vstring($version), ", but the only allowed versions are $vs";
 }

sub generate_VERSION
 {
 my $export_def= shift;  # might not have been blessed yet.
 return sub {  # this becomes the VERSION function in the exporting module.
    my ($home, $version, $client)= @_;
    $client= _calling_client() unless defined $client;  # allow as optional argument
    if (defined $version) {
       # assure correct version / set desired version
       $version= normalize_vstring($version);
       Err "The version for this module has already been specified for module $client as ", _format_vstring ($export_def->{'..client_default_version'}{$client})
          if exists $export_def->{'..client_default_version'}{$client};
       my $max_version= $export_def->{'..max_VERSION'} || _get_VERSION ($home);  # first time, called before setup.
       Err "$client requested version ", _format_vstring ($version), " but module $home is only version ", _format_vstring ($max_version)
          if $version gt $max_version;
       _check_allowed_versions ($version, $export_def->{'.allowed_VERSIONS'});
       $export_def->{'..client_default_version'}{$client}= $version;
       }
    else {
       # fetch version
       return $export_def->{'..client_default_version'}{$client}  if exists $export_def->{'..client_default_version'}{$client};
       # never explicitly specified, so use the module's actual current version.
       $version= $export_def->{'..max_VERSION'} || _get_VERSION ($home);
       $export_def->{'..client_default_version'}{$client}= $version;  # once I decide, must always use the same result.
       return $version;
       }
    }
 }

sub get_import_version
 {
 my ($self, $client)= @_;
 unless (exists ($self->{'..client_default_version'}{$client})) {
 Err "(Exporter::VA) you must specify a version to import, since the module has no default."
    unless exists $$self{'.default_VERSION'};
    $self->{'..client_default_version'}{$client}= $$self{'.default_VERSION'};
    print VERBOSE "(Exporter::VA) import version not specified, using .default_VERSION\n"
       if $$self{'.verbose_import'};
    }
 return $$self{'..client_default_version'}{$client};
 }

sub _format_vstring($)
 {
 return sprintf ("v%vd", shift);
 }


sub _normalize_vstring_list
 {
 my $list= shift;
 for (my $loop= 0; $loop < @$list; $loop+=2) {
    normalize_vstring ($$list[$loop]);
    }
 bless $list, "ARRAY-seen";
 }

sub _match_vstring_list
 {
 my ($list, $desired_version)= @_;
 # list is [ v1, item1, v2, item2, v3, item3, ... , vn, itemn ]
 # match $desired_version between two v's, and return (v,item).
 for (my $index=0;  $index < scalar(@$list);  $index+=2) {
    my $ver_at_index= $$list[$index];  # >> might need to normalize it.
    next unless ($ver_at_index ge $desired_version);
    # I get here when I found or passed my spot.
    return @$list[$index, $index+1]  if ($ver_at_index eq $desired_version);  # found it exactly
    # otherwise I passed it.
    return (undef, undef, "desired version not found")  if $index == 0;  # before the first, is not present.
    return @$list[$index-2, $index-1];
    }
 # after the last, take the last.  Should cap at Module's version, but that was checked earlier when VERSION was called.
 return @$list[-2,-1];
 }
 
sub generate_import
 {
 my $export_def= shift;
 return sub {
    my $home= shift;
    $export_def->setup ($home);  # happens first time used.
    my $client= _calling_client();
    my $version= $export_def->get_import_version ($client);
    $export_def->callback ('.&begin', $client, $version, '.&begin', \@_);
    @_ = ':DEFAULT'  if (!@_ && defined $export_def->{':DEFAULT'});
    $export_def -> export ($client, $version, \@_);
    $export_def->callback ('.&end', $client, $version, '.&begin', \@_);
    $export_def->_process_worklist();
    --$$export_def{'.verbose_import'}  if $$export_def{'.verbose_import'};
    }
 }

sub export
 {
 my ($self, $module, $version, $items)= @_;
 $items= [$items]  unless ref $items eq 'ARRAY';  # allow single item
 while (my $item= shift @$items) {
    my $verbose= $$self{'.verbose_import'};  # must check object each time, not cache it.
    print VERBOSE "(Exporter::VA) ===processing import parameter ($item)===\n"    if $verbose;
    if (ref $item) {
       print VERBOSE "(Exporter::VA) It's not a scalar, so invoking .&unknown_type callback.  It's out of my hands.\n"  if $verbose;
       $self->callback ('.&unknown_type', $module, $version, $item, $items);
       }
    else {
       if ($item =~ /^[\$\@\%\*\&]?\w+$/ or $item =~ /^-/ or $item =~s /^(<\w+)>$/$1/) { $self->export_one_symbol ($module,$version,$item,$items) }
       elsif ($item =~ /^:\w+$/) { $self->export_one_tag ($module,$version,$item, $items) }
       else { 
          print VERBOSE "(Exporter::VA) It's not syntactically correct, so invoking .&unknown_feature callback.  It's out of my hands.\n"  if $verbose;
          $self->callback ('.&unknown_feature', $module, $version, $item, $items);
          }
       }
    }
 }


{
my %thing= reverse (SCALAR=>'$', ARRAY=>'@', HASH=>'%',CODE=>'&',IO=>'<',GLOB=>'*');
sub _resolve_by_name
 {
 my ($item, $home, $name)= @_;
 $name= $item  if $name eq '';  # blank string means "same".
 my $sigil= ($name =~ s/^([\$\@\%\&\<\*])//) ? $1  : '&';
 my $thing= $thing{$sigil};
 Err "(Exporter::VA) Improper export definition for item $item: invalid symbol name syntax: $name"  unless defined $thing;
 no strict 'refs';
 my $globref= ${"$home\::"}{$name};
 Err "(Exporter::VA) Symbol to export does not exist: *$home\::$name"  unless defined $globref;
 return *{$globref}{$thing};
 } # _resolve_by_name
} # private vars scope

sub _resolve_by_versionlist
 {
 my ($self, $module, $desired_version, $item, $param_tail)= @_;
 my $versionlist= $$self{$item};  # I still have the $item name for callbacks and error messages
 my ($got_version, $result)= _match_vstring_list ($versionlist, $desired_version);
 print VERBOSE "(Exporter::VA) wanted $item version ", _format_vstring($desired_version), ", choose ", _format_vstring($got_version), "\n"
   if $$self{'.verbose_import'};
 return resolve (@_[0..4], $result);
 }

sub _resolve_by_hardlink
 {
 my ($item, $hardlink)= @_;
 # This function just provides error checking.  Returning wrong kind of ref can cause problems!
 Err "(Exporter::VA) Improper export definition for item $item: ref to scalar must contain \\\\&code"  unless ref($hardlink) eq 'CODE';
 return $hardlink;
 }
 
sub resolve
 {
 my ($self, $module, $version, $item, $param_tail, $value)= @_;
 $value= $$self{$item}  unless defined ($value);  # normally lookup, can supply ahead of time for recursive call.
 if (!defined $value && $item =~ /^&(.+)$/) {
    # it might be entered in the export def without the sigil.
    my $base= $1;
    $value= delete $$self{$base};
    if (defined $value) {
       $$self{$item}= $value;
       print VERBOSE "(Exporter::VA) adding leading & to ($base) entry in export definition\n"  if $$self{'.verbose_import'};
       }
    }
 return $self->callback ('.&unknown_import', $module, $version, $item, $param_tail)
    unless defined $value;  # not listed in export def.
 my $type= ref $value;  # what is it?  Lots of different ways to list it.
 return _resolve_by_name ($item, $$self{'..home'}, $value)  unless $type;  # scalar is a name in the home package.
 return &_resolve_by_versionlist  if $type eq 'ARRAY-seen';
 if ($type eq 'ARRAY') {
    _normalize_vstring_list ($value);
    return &_resolve_by_versionlist;
    }
 return $value->(@_)  if $type eq 'CODE';
 return _resolve_by_hardlink ($item, $$value);
 Err "(Exporter::VA) Invalid export definition for item $item";
 }

sub export_one_symbol # or pragma
 {
 my ($self, $module, $version, $item, $param_tail)= @_;
 my $sigil= ($item =~ s /^([\$\@\%\*\&\-\<])//) ? $1 : '&';
 Warn qq((Exporter::VA) warning: importing symbol "$sigil$item" which begins with an underscore)
    if substr($item,0,1) eq '_';
 my $X= $self->resolve ($module, $version, "$sigil$item", $param_tail);
 if (defined $X && $sigil ne '-') {  # skip the import if it's callback-only
    my $worklist= $self->worklist();
    my $name= "${module}::$item";
    $$worklist{$name}= $X;  # duplicates take last resolution with no errors.
    print VERBOSE qq(Got It:  *{"${module}::$item"}= $X\n)  if $$self{'.verbose_import'};  
    }
 }

sub worklist
 {
 my $self= shift;
 return $$self{'..worklist'};
 }
 
sub _process_worklist
 {
 my $self= shift;
 my $worklist= $self->worklist();
 no strict 'refs';
 while (my ($left, $right)= each (%$worklist)) {
    eval { *{$left}= $right; }; # this better be the right kind of thing!
    if ($@) {
       Err "(Exporter::VA) Could not process import for item '$left' = $right.";
       }
    }
 }
 
sub export_one_tag
 {
 my ($self, $module, $desired_version, $item, $param_tail)= @_;
 Warn qq((Exporter::VA) warning: importing tag "$item" which begins with an underscore)
    if substr($item,1,1) eq '_';
# my $home= $$self{'..home'};  # package I'm exporting =from=
 RESTART:
 my $list= $$self{$item};
 Err "(Exporter::VA) no such export tag '$item'"  unless defined $list;
 my $type= ref $list;
 if ($type eq 'ARRAY') {
    # identify it, and change $type.
    return  if @$list == 0;  # empty list is OK.
    if (is_vstring($$list[0])) {
       _normalize_vstring_list ($list);
       $type= 'ARRAY-seen';
       }
    else {
       $type= 'ARRAY-tags';
       bless $list, $type;
       }
    }
 if ($type eq 'ARRAY-seen') {
    my ($got_version, $result)= _match_vstring_list ($list, $desired_version);
    print VERBOSE "(Exporter::VA) wanted $item version ", _format_vstring($desired_version), ", choose ", _format_vstring($got_version), "\n"
       if $$self{'.verbose_import'};
    $item= $result;
    goto RESTART;
    }
 elsif ($type eq 'ARRAY-tags') {
 my @copy= @$list;
    $self->export ($module, $desired_version, \@copy);
    }
 ## would add support for other types here, e.g. callbacks.
 else { Err "(Exporter::VA) export tag '$item' is not a list ref" }
 }
 
sub callback
 {
 my $self= shift;
 my $cb_name= shift;
 my $func= $$self{$cb_name};
 # they should be fully populated, putting in default behavior if it doesn't exist.
 # this is not "try to callback..." so if not found it is an error.
 $func-> ($self, @_);
 }

{
my %defaults= (
   '.&unknown_type' => sub { Err "(Exporter::VA) import parameter is not a string" },
   '.&unknown_feature' => sub { Err "(Exporter::VA) import parameter \"$_[3]\" is not syntactically correct" },
   '.&unknown_import' => sub { Err "(Exporter::VA) import parameter \"$_[3]\" is not listed as an export" },
   '.check_user_option' => sub { return "unknown option"},
   '.warnings' => 1,
   '.&begin' => sub {},
   '.&end' => sub {},
   '--verbose_import' => sub {  ++$_[0]->{'.verbose_import'} },
   '--dump' => sub { $_[0]->dump() }
   );


sub _populate_defaults
 { # helper for setup.
 # populate callbacks and settings that were not specified
 my $self= shift;
 while (my ($key,$value)= each %defaults) {
    $$self{$key}= $value  unless exists $$self{$key};
    }
 no strict 'refs';
 $$self{'.default_VERSION'}= normalize_vstring (${"$self->{'..home'}::VERSION"})  unless exists $$self{'.default_VERSION'};
 }

} # end scope for populate_defaults


sub _expand_plain
 {
 my $self= shift;
 my $plainspec= delete $$self{'.plain'};
 return unless defined $plainspec;
 while (my $value = shift @$plainspec) {
    $value =~ /^([\$\@\&\%:<])?(\w+)>?$/  or Err "(Exporter::VA) item '$value' in .plain list is not a legal symbol or tag name";
    my ($sigil, $body)= ($1,$2);
    $sigil= '&'  unless defined $sigil;
    if ($sigil eq ":") {
       # this one is different
       push @$plainspec, @{$$self{$value}};
       # could do more error checking: make sure tag exists, and doesn't contain v-string list.
       }
    $value= "$sigil$body";
    next  if exists $$self{$value};
    next  if $sigil eq '&' && exists $$self{$body};  # present without the leading & for a function
    next  if $sigil eq '<' && exists $$self{"$body>"};  # present with trailing > for a handle
    # not already present, so add it.
    $$self{$value}=$value;
    }
 }

sub _get_VERSION
 {
 my $home= shift;
 no strict 'refs';
 my $v= ${"${home}::VERSION"};
 Err "(Exporter::VA) module $home does not contain a package global \$VERSION"
    unless defined $v;
 return normalize_vstring ($v);
 }

{ # extra scope for variable local to function

my %check_code= (
  # could point to more detailed checking function, or just 1 for OK/allowed with no additional testing.
   '.allowed_VERSIONS' => 1,
   '.&begin' => 1,
   '.check_user_option' => 1,
   '.default_VERSION' => 1,
    '.&end' => 1,
    '.plain' => 1,
    '.&unknown_feature' => 1,
    '.&unknown_import' => 1,
    '.&unknown_type' => 1,
    '.verbose_import' => 1,
    '.warnings' => 1
    );
 
 sub _check_warning_option($$$)
 {
 my ($self, $item, $value)= @_;
 if ($item =~ /^\.&?\p{IsUpper}/) {
   # a user-defined option.
   $self->check_user_option ($item);
   }
 return if $item =~ /^\.\./;  # internal state information
 # check for known options.
 my $checker= $check_code{$item};
 if (!defined $checker)  { Warn qq{(Exporter::VA) unknown option present: "$item"} }
 elsif (ref $checker) { $checker->($item,$value) }
 # else it exists but doesn't have special checking code, so no messages.
 }

} # scope for _check_warning_option

sub _check_warning_tag($$)
 {
 my ($item, $value)= @_;
 }

sub _check_warning_pragma($$)
 {
 my ($item, $value)= @_;
 }

sub _check_warning_identifier($$)
 {
 my ($item, $value)= @_;
 }

sub _check_for_warnings
 {
 my $self= shift;
 while (my($key, $value)= each %$self) {
    my $firstchar= substr($key,0,1);
    if ($firstchar eq '.')  { _check_warning_option ($self, $key, $value) }
    elsif ($firstchar eq ':')  {_check_warning_tag ($key, $value) }
    elsif ($firstchar eq '-')	{_check_warning_pragma ($key, $value) }
    else  {_check_warning_identifier ($key, $value) }
    }
 }

sub setup
 {
 my ($self, $home)= @_;
 my $existing_home= $$self{'..home'};
 if (defined $existing_home && $existing_home ne $home) {
    Err "(Exporter::VA) reuse of \%EXPORT in module $home is not allowed.";
    }
 $$self{'..home'}= $home;
 $$self{'..worklist'}= {};
 $$self{'..max_VERSION'}= _get_VERSION ($home);
 $self->_expand_plain();
 $self->_populate_defaults();
 if (exists $$self{'.allowed_VERSIONS'}) {
    $_= normalize_vstring($_)  foreach (@{$$self{'.allowed_VERSIONS'}});
    }
 $self->_check_for_warnings()  if $$self{'.warnings'};
 }

{
my $client_export_def;

sub begin
 {
 my ($blessed_export_def, $caller, $version, $symbol, $param_list_tail)= @_;                  
 $client_export_def= find_export_def ($caller, $param_list_tail);
 }
 
sub find_export_def
 {
 my ($caller, $params)= @_;
 # first, try to locate hash ref in parameter list.
 foreach my $index (0..scalar(@$params)-1) {
    my $val= $$params[$index];
    if (ref ($val) eq 'HASH') {
       splice @$params, $index, 1;  # remove it
       splice @$params, $index-1, 1
          if $index>0 && $$params[$index-1] eq '-def';  # remove optional explicit switch
       return $val;  # return it
       }
    }
 # look for package variable in caller.
 no strict 'refs';
 return \%{"$caller\::EXPORT"};
 }

sub export_import  
  # called to export a custom import function to *my* client, when Export::VA is used.
 {
 my ($VA_export_def, $caller, $version, $symbol, $param_list_tail)= @_;
 $client_export_def= bless $client_export_def, "Exporter::VA";
 return generate_import ($client_export_def);
 }


sub export_VERSION
  # called to export a custom VERSION function to *my* client, when Export::VA is used.
 {
 # my ($VA_export_def, $caller, $version, $symbol, $param_list_tail)= @_;
 # the above line documents the parameters, but I don't need any of them so it's commented out.
 return generate_VERSION ($client_export_def);
 }


sub export_AUTOLOAD
  # called to export a custom AUTOLOAD function to *my* client, when Export::VA is used.
 {
 # my ($VA_export_def, $caller, $version, $symbol, $param_list_tail)= @_;
 # the above line documents the parameters, but I don't need any of them so it's commented out.
 return _generate_AUTOLOAD ($client_export_def);
 }

 
}  # end scope around $client_export_def

sub autoload_symbol
 {
 my ($self, $symbol, @extra)= @_;
 my %memory;
 my $home= $self->{'..home'};
 my $thunk= sub {
    my $retval= eval {
       my $caller= _calling_client();  # so I don't have to figure it out multiple times
       my $f= $memory{$caller};
       unless (defined $f) {
          $f= $memory{$caller}= $self->resolve ($caller, $home->VERSION(undef,$caller), '&'.$symbol, [@extra]);
          }
       goto &$f;
       };
    if ($@) {
       carp "(Exporter::VA) Cannot redirect to versioned function ($@)";
       }
    return $retval;
    };
 no strict 'refs';
 *{"${home}::$symbol"}= $thunk; 
 }

sub _generate_AUTOLOAD
 {
 my $client_export_def= shift;
 return sub {  # the generated AUTOLOAD
    my $AUTOLOAD= $Exporter::VA::AUTOLOAD;  # save the global in case of recursion.
    my $func= $AUTOLOAD;
    $func =~ s/.*:://;  # not checking the actual module name.  Might be inherited or re-routed or something.  I shouldn't care, right?
    Err "(Exporter::VA) Generated $client_export_def->{'..home'}::AUTOLOAD can't find export definition for $func."
       unless exists $client_export_def->{$func} || exists $client_export_def->{'&' . $func};
    $client_export_def->autoload_symbol ($func);
    goto &$AUTOLOAD;  # try it again.
    }
 }

## main code.
{

my $export_def= bless (\%EXPORT, __PACKAGE__);
use vars qw/*import *VERSION/;  # silence a warning when syntax checking the .pm by itself
*import= generate_import ($export_def);
*VERSION= generate_VERSION ($export_def);
}


1;
__END__

=head1 AUTHOR

John M. Dlugosz

=head1 SYNOPSIS

In module ModuleName.pm:

	package ModuleName;
	use Exporter::VA qw/import AUTOLOAD VERSION/;

	our %EXPORT= ( # all configuration done in this one hash
		foo => [ v1.0, 'foo_old', v2.0, 'foo_new' ],
		bar => 'bar_internal',
		baz => 'baz',
		fobble => \&figure_it_out, # parameter list is (caller, version, symbol, param-list tail)
		bobble => \\&_boble_internal,
		'$x' => '$x',
		'$y' => \\$y,  # a hard reference rather than a name
		':tagname' => [ 'foo', 'bar' ],
		':DEFAULT' => [ v1.0, ':_old_imports', v2.3, ':_new_imports' ],
		':_old_imports' => [ 'foo', 'bar', 'baz', 'fobble' ],
		':_new_imports' => [ 'fobble' ],
		'.option' => "value",
		'.default_VERSION' => v1.5,
		'.warnings' => 1
	);

In other files which wish to use ModuleName:

	use ModuleName;

	use ModuleName v2.1;

	use ModuleName v2.1 qw/ foo bar fobble $y/;

=head1 DESCRIPTION

This main incentive in creating this exporter is to allow modules to be updated and
get rid of default exports in newer releases, while still maintaining compatibility with
older code.

=head2 What it Gives the Client's 'use' Statement

If ModuleName gets its C<import> function via C<Exporter::VA>, then the client that
C<use>s ModuleName will generally see these features:

	use ModuleName v2.3.4 qw( foo &bar $x -verbose :constants );

=over 4

=item names

List the names of the things you want imported.  Functions may omit the C<&> character.
You can import C<&functions>, C<$scalars>, C<%hashes>, C<@arrays>, and even
C<< <FILES> >>.

=item tags

A group of things may be named with a tag, beginning with a C<:> character.  Naming this
will expand into the group it represents.

=item pragmas

An item may be listed which has some effect on the import process but doesn't actually import a
symbol by that name.  Ideally, these begin with a leading C<-> (dash) character, but any symbol can
actually be a pragma.  Pragmas can take arguments.

Different clients of a module can have different options in effect which influence the behavior of
the module, and the module can, with the help of C<Exporter::VA>, keep track of which client
has which settings and react accordingly.  For example, some clients may activate C<-verbose>
mode, and others leave it off.

Those that begin with a double-dash are handled by the C<Exporter::VA> module itself, and
are not defined by the module you are C<use>-ing.  So, their meaning and availability will
be the same on any module that is built with C<Exporter::VA>.

These are C<--verbose_import>, which will detail the import process
for purposes of troubleshooting; and C<--dump> which will print the state of the
C<%EXPORT> definition and internal state.

=back

I said it will I<generally> have these features because C<Exporter::VA> is very customizable.
Modules with unique needs that had their own exporter code can hopefully "upgrade" to C<Exporter::VA>
and get it to work like it did before, gaining the versioning ability.

A future version may support patterns as seen in the classic C<Exporter> module.  Specifically, a
parameter beginning with C<!> or C</> would be handled internally, as would parameters that
are qr's rather than strings.

Parameters beginning with C<+> will never be used specially by C<Exporter::VA>, so if you
want to add a feature that uses a different prefix symbol, this is a good one to use.

=head2 Module Versioning

The syntax of the C<use> statement allows for a version number as an
indirect object (that is, no comma follows it).  A module may export different things
depending on the requested version.  Tags may expand into different lists based on
version.  Specifically (and this was the original motivation for writing this), the C<:DEFAULT>
tag (equivilent to the C<@EXPORT> list in the classic Exporter module) may
contain different things based on version.

=head2 How to Incorporate

The module that wishes to draw upon C<Exporter::VA> for its export needs can simply import
the C<import> and C<VERSION> functions.  Note that this is different from the classic Exporter
module in that it needs C<use> instead of C<require>, and does not inherit from it.

You can import the C<import> function and C<Exporter::VA> will provide you with one.  If you
prefer, you can write C<import> yourself to do some enhancements, and then from it call one
of the helper functions.

You can also import the C<AUTOLOAD> function, which is an easy way to lazy-generate any
aliased functions that are called via module-qualified syntax.  There are other ways to do this,
described later.

All information for configuring the module's use of C<Exporter::VA> is given in a single hash.
By default, this will be the C<%EXPORT> hash found in the calling package.

Or, you can include a hashref as a parameter to the C<use>, and this will specify the
destination.

	my %Export= ( #...
	use Exporter::VA (\%Export, ':normal');  # look ma, no package globals!

	use Exporter::VA ('import', {
		foo => \\&internal_foo,
		bar => \\&internal_bar
		} );  # put it all inline in this statement.

However it's found, this document will call this information the C<%EXPORT> definition.

=head2 Keys in the %EXPORT definition

There are several kinds of keys that may be present in the C<%EXPORT> definition, and
they have different purposes and different usage rules.

=over 4

=item symbols

If the hash key begins with a Perl sigil, left-angle (a pseudo-sigel for file handles) or a Perl 
identifier character (to be exact, C<< /^[$@%*&\w<] >>)
it names a symbol that the module's user may import by that name.  If there is no sigil, then it
assumes a C<&>, so you can say C<foo> instead of C<&foo>.

=item tags

If the hash key begins with a C<:> character, then it names a list of other names.  The module's user
may use this tag to import the whole list, as with the traditional C<Exporter> module.

=item pragmas

If the hash key begins with a C<-> (dash) character, then the module user may "import" it to trigger
code or special features of the module.

=item options

If the hash key begins with a C<.> (dot) character, it has special meaning to C<Exporter::VA> and is
used as an option or parameter to configure the module's use of the exporter.

=back

=head2 symbols

If the hash key begins with a Perl sigil or a Perl identifier character (to be exact, C<< /^[$@%*&\w<] >>)
it names a symbol that the module's user may import by that name. 

The value may be a name, a hard link, a callback, or a version list.

=over 4

=item name

If the value is a scalar, then it is the name of the symbol within the package to export.  This
does not have to be the same as the export name that the module's user will see.

	%EXPORT= (
		'&foo' => "foo",  # & is optional for functions
		'$bar' => '$_internal_bar',
		'baz' => ""  # means "same".
		);

As a special case, an empty string means that the internal name is the same as the
export name.  C<< foo => "foo" >> can also be specified as C<< foo => '' >>.  See also the L<.plain>
option.

A value of C<undef> means that the symbol is not available for import.  This is the same as not
listing it at all for a simple name value, but is useful as part of a version list, to indicate that the function
was dropped at some point.

This name is matched against the defining package's symbol table.  It does not handle inheritence or
fancier things.  If you need that, use a hard link or callback instead.  There is no plan to support
inherited methods, since (virtual) methods are commonly not exported anyway and it is trivial to
work-around for the desired effect without bothering the module's client.

=item non-scalars

If the value is not a scalar or C<undef>, than it is a reference of some kind.  This module distinguishes several
types based on the kind of reference: array ref is a version list, code ref is a callback, scalar ref is a hard link.
Others are errors.

=item version list

If the value is an array reference, then it specifies alternating v-strings and symbol values.

	foo => [ v1.0, 'foo_old', v2.0, 'foo_new' ]

It must begin with a v-string that is the oldest supported version.  That is followed by the value to use for
that version and later, until it changed with the next named version, and so on.  The last value is "current"
and used up to and including this module's stated C<$VERSION>.

So, in the above example, if the module's user called for:

	use ModuleName v1.78 ('foo');  # note no comma after v-string

then C<ModuleName> will export its C<foo_old> function as the caller's C<foo>.

The values in this list in the even positions are the same kinds of values used for
symbol name entries, except for another version list.  It may be a name, hard link, callback, or C<undef>.

=item callbacks

If the value is a code reference, then it specifies a callback function.  This code will be called
when the symbol is being imported, and can do something more complex than the version list
allows.

	%EXPORT= (
		'&foo' => \&figure_it_out_later,
		'$bar' => sub { ... logic goes here ... },
		'%fible' => sub { \%internal_fible }
		);

When that line is triggered at import time, the code is called with the following parameters:

	sub figure_it_out_later
	 {
	 my ($blessed_export_def, $caller, $version, $symbol, $param_list_tail)= @_;

The C<$caller> is the package name of the module's user; that is, the one doing
the importing.  C<$version> is the v-string of the version he's asking for.  C<$symbol>
is the name of the symbol he's asking for (a function name will have the C<&> added).
Finally, the last argument is an array ref of the rest of the parameter list to C<import>, which
this callback may inspect or modify (see L<pragmas|pragmas>, below).

(More technically, the C<$param_list_tail> will contain the rest of the items in the tag definition
if triggered during a C<:TAG> import, or the rest of the "batch" if extension code triggers importing
of a list of items programmatically.)

To indicate success and that a symbol was found, function must return a reference to the proper 
type of thing, which is what will be placed in the caller's package.

To indicate success and that no symbol should be imported (that is, a pragmatic import) the function
returns C<undef>.  The intent is for pragmatic imports to begin with a dash, but for compatibility
with existing modules that may want to adopt C<Exporter::VA>, any symbol may silently "fail" to
import this way, without error.

To indicate an error, C<die> with an error string.

=item hard links

As explained above, if the C<%EXPORT> definition contains a text string like C<< '&foo' => "&foo" >>, then when triggered
it will symbolically reference C<&ModuleName::foo>.  Instead, you can specify a hard-link, and
not even have a name that is visible outside the package (or even the scope!).

In the section on L<callbacks|callbacks>, the callback C<< '%fible' => sub { \%internal_fible } >>
ignores the parameters and always returns a reference to the same thing.  This is exactly what is
meant by a hard-link here.  Only there is a shortcut for doing it:

	'%fible' => \\%internal_fible

Basically, use a double-reference to the desired symbol, and that will directly be used at export
time as opposed to finding it by name first.

Syntactically, this is a reference to a scalar which must itself contain a reference to the right
kind of thing.  It is sensible for the normal meaning of the backslash in Perl, adding another
layer of deferring things.

=back


=head3 tags

If the hash key in the C<%EXPORT> definition begins with a C<:> character, then it names a list of other names.
The module's user may use this tag to import the whole list, as with the traditional C<Exporter> module.

The value is a list ref.  It may either be a list of names, or a list of alternating v-strings and tags.

A list of names is simply that.  The contents of the list replace the tag's name in the C<import>
parameter list.  So, given

	%EXPORT= (
		apple => ...
		banana => ...
		pear => ...
		potato => ...
		cheeze => ...
		':fruit' => [ qw/apple banana pear/ ]
	);

Then the module's user might say

	use ModuleName v1.78 qw/potato :fruit cheeze/;

to mean the exact same thing as 

	use ModuleName v1.78 qw/potato apple banana pear cheeze/;

The other form is used to version a list.  The concept is the same as the L<version list|version list> used
for symbol values: The list alternates v-strings and other tag names.  The original tag is replaced by
the one that matches the desired version, and then processing continues.

For example, given

	%EXPORT= (
		':list' => [ v1.0, ':_old_list', v2.3, ':_new_list' ],
		':_old_list' => [ 'foo', 'bar', 'baz', 'fobble' ],
		':_new_new' => [ 'fobble' ]
	);

then 

	use ModuleName v1.2 ':list';

means the same thing as

	use ModuleName ':_old_list';

and

	use ModuleName v2.4 ':list';

means the same thing as

	use ModuleName ':_new_list';

(except that directly importing something that begins with an underscore gives a warning).

=head4 the :DEFAULT tag

If there is nothing specified in the import parameter list, then it behaves as if C<:DEFAULT> was
specified.  This is how you list what gets imported if you don't specify otherwise, and is the
equivilent of C<@EXPORT> in the traditional C<Exporter> module.

=head4 symbols and tags work together

If a package imports the default in this example, it will note that C<foo> was imported in versions 
before v2.3 but dropped as a default in that version. But, in version 2.0 the implementation changed, 
so it will pull in C<foo_old> if the requested version is less than 2, or C<foo_new> if between 2.0 and 2.3, or 
not import it at all if 2.3 or later.

	%EXPORT= (
		foo => [ v1.0, 'foo_old', v2.0, 'foo_new' ],
		':DEFAULT' => [ v1.0, ':_old_imports', v2.3, ':_new_imports' ],
		':_old_imports' => [ 'foo', 'bar', 'baz', 'fobble' ],
		':_new_imports' => [ 'fobble' ],
		# ... others ...

Looking at it step-by step, the module changed what was imported by default.  In the traditional
system, that's like changing C<@EXPORT> and moving them to C<@EXPORT_OK> instead.

Meanwhile, the implementation of C<foo> changed in version 2.0.  The decision of which version of
C<foo> to import is independant and orthogonal of the decision of whether C<foo> gets imported by default.

=head3 pragmas

If the hash key in the C<%EXPORT> definition begins with a C<-> (dash) character, then it defines a pragmatic
import.  Also, unlike other "symbol" names, since this is not going to define a Perl symbol, it is not
limited to legal identifier names.  Any character that does not otherwise cause problems may be used
in an option that begins with a dash.

This is used to trigger a callback, without actually importing anything.  For example, given

	%EXPORT= (
		'-prag' => \&callme,
		# ...

then the calling module can say:

	use ModuleName v1.0 qw/ foo -prag bar/;

and between doing the work of resolving C<foo> and resolving C<bar>, it will trigger the function C<&callme>.  
This is I<exactly> like a callback for a symbol, except that if the symbol name begins with a dash it is
thrown away after it resolves it, and doesn't put it into the calling module's package.  (Note that "resolving" here
means figuring out what to import and adding it to a L<worklist|worklist>.  It doesn't actually modify the caller's namespace until
later.)

Since a callback can see the rest of the import parameter list and modify it, a pragma can take
parameters by shifting them off the list.

A pragma might be used to customize the behavior of a module.  The module can remember the
settings associated with each importer by using a hash keyed by the caller (importer).

	%EXPORT= (
		'-strict' => sub { my $caller= shift; $strict{$caller}=1; }

=head3 options

If the hash key in the C<%EXPORT> definition begins with a C<.> (dot) character, it has special meaning 
to C<Exporter::VA> and is used as an option or parameter to configure the module's use of the exporter.

Those that begin with a C<&> symbol (after the initial dot) take code references that are invoked
just like export callbacks.

=over 4

=item .allowed_VERSIONS

The version asked for must be on this list.  Normally, version numbers are checked to see if they are
between version numbers where things changed, but the exact number doesn't matter.	If you specify
a list here, then only versions on this list are accepted.

		'.allowed_VERSIONS' => [
			v1.0, # initial relase
			v1.1, # minor fixes

=item .&begin

This is called just like a symbol callback, before proceeding with processing all the symbols
in the import list.  Any return value is ignored.


	%EXPORT= (
		'.&begin' => sub {
		  my ($blessed_export_def, $caller, $version, '.&begin', $param_list_tail)= @_;
		  #...


=item .check_user_option

		'.&check_user_option' => &checkfunction

This can be used to supply a checking function without having to derive a class.  It works exactly
like the C<L<check_user_option>> method.

If you have callbacks that respond to user-defined options, but did not have to derive a class
from C<Exporter::VA> to do what you needed, then use this to implement warning-checking on
those options.

=item .default_VERSION

If the module importer does not specify a version in its C<use> statement, then this value is used.
Typically, when switching from C<Exporter> to C<Exporter::VA> to facilitate reducing the list of
things exported by default, or versioning a symbol, set the C<.default_VERSION> to the last version
before the change.  Then, any code that doesn't specify otherwise will get the backward-compatible imports.

		'.default_VERSION' => v1.99,  # changed stuff with 2.0, must ask for new stuff.

If not specified, then a v-string is required in the C<use> statement.

=item .&end

Just like C<.&begin>, but called after the C<import> list has been all processed, and the symbol parameter
of course is C<'.&end'> to match.

Note that you may examine and alter the L<worklist|worklist> at this time.

=item .plain

This is a list ref that contains symbol names.  Before processing begins, everything on it is
added to the C<%EXPORT> definition as self-named symbols without versioning or aliases.  This
makes it easy to have something like the traditional C<@EXPORT> list, copying such a list when
upgrading to use C<Exporter::VA> without reformatting it, or just being more succinct.

For example, 

	%EXPORT= (
		'.plain' => [qw/foo $x &zed/],

will generate (recall that an empty string means "same name as the key")

	%EXPORT= (
		'&foo' => "",
		'$x' => "",
		'&zed' => "",

You can also list a C<:tag> name here, and this will expand to the tag names.  The tag must
be a list of names, not an alternating v-string/name list.

This is similar to the traditional C<Exporter::export_tags> and C<Exporter::export_ok_tags>, in
that it it prevents you from having to invidually list as exports all the items that are also in
the tag's definition list.

	%EXPORT= (
		'.plain' => [qw/:DEFAULT fozzle/],
		':DEFAULT' => [qw/foo bar baz/],
		bar => '_bar_internal'
		);

The above example will add plain export entries for C<foo> and C<baz> as well as
C<fozzle>, but silently ignore C<bar> as redundant since it is already listed as an export.


=item .&unknown_feature

	%EXPORT= (
		'.&unknown_feature' => sub {
		  my ($blessed_export_def, $caller, $version, $weird_parameter, $param_list_tail)= @_;
		  #...

Before generating an error for an C<import> parameter that is syntactically incorrect,
this callback will be tried.

If it returns, then the module assumes that this callback handled the whatever-it-was.  If the callback
cannot handle the parameter, it should fail by calling C<die>.

The callback can do its work by manipulating the object and the caller's namespace, and calling
the supplied implementation functions such as C<L<export>>.

For example,

	use ModuleName 1.0 qw/foo -prag +huh bar/;

will trigger C<.&unknown_feature> when the C<"+huh"> parameter is reached during processing.
You can use this to implement the classic C<Exporter>'s feature of having a leading C<!> remove
an import (see L<worklist|worklist>), for example.

=item .&unknown_import

	%EXPORT= (
		'.&unknown_import' => sub {
		  my ($blessed_export_def, $caller, $version, $symbol, $param_list_tail)= @_;
		  #...

This callback is invoked for an unlisted symbol.  It must return C<undef> to indicate no
error but no real export either (i.e. a pragmatic import) or a reference to the correct type 
of thing based on the name in C<$symbol>, or C<die> if the C<$symbol> could not be
handled.  The default implementation indicates an error for any symbol.

=item .&unknown_type

	%EXPORT= (
		'.&unknown_type' => sub {
		  my ($blessed_export_def, $caller, $version, $strange_import_param, $import_list_tail)= @_;
		  #...

If the import list contains something that is not a scalar, then it is passed to this callback.  The
thing in question is C<$strange_import_param>.

This is handy for implementing modules that take a hash ref or other object in addition to export
names.  This can also be done by making it follow a pragmatic import, or looking for it in a C<.&begin>
pass.

This callback must do whatever it needs to in your module.  It doesn't return anything to the export
engine (so C<die> to fail).  The callback may call C<< $self->export >> with more symbols, if it needs to do any
real exporting.

=item .verbose_import

If true, it will print trace statements as the specifications are being processed, and explain what is
actually being imported into modules.  If false, it stays mute except for warnings or errors.

When importing is complete and C<.verbose_import> is true, then C<.verbose_import> is decremented.  This
means that setting it to 1 will operate as a one-shot, only reporting details the I<first> time it is
C<use>d.  If you set it to 2, then two calls to this module's C<import> will be be reported, and so on.

If you don't define a C<--verbose_import> key in the C<%EXPORT> definition, then this module will 
automatically define a C<--verbose_import> pragmatic import that will activate verbose mode if used.

	use ModuleName 2.0 qw/ --verbose_import foo bar/;

Of course, it doesn't take effect until after that C<--verbose_import> parameter has been processed,
so it will not report setup and things to its left.

Any pragmas that refer to the import process itself rather than any resulting semantics of
the module will begin with a double-dash.

=item .warnings

If the value is true, then extra keys that are not known options are reported as warnings, and
other possible typos are reported in the C<%EXPORT> definition.  If false, then it doesn't go out
of its way to look for problems, speeding up the process.

The default value, if this option is not given, is 1.  You must specify

		.warnings => 0,

to I<disable> these warnings.

=item user-defined and reserved

To prevent typos, when I<warnings> are enabled, the C<%EXPORT> definition is scanned for
unknown options.

If you derive from or otherwise extend C<Exporter::VA> and wish to add more options, use
option names beginning with capital letters (or a C<&> followed by a capital letter).  All others are 
reserved for future versions of this module.  (A I<capital> can be any Unicode value with the
IsUpper property.)

Also, supply a method C<check_user_option> in your derived class or use the C<.check_user_option> option
to declare your additional options.

=back

=head2 Quick guide to difference compared to classic Exporter

Also see the Exporter-VA-Convert.perl program, which will automatically read a module and tell you
exactly what to change and show you the equivilent C<%EXPORT> definition.

With classic Exporter,

	package SomeModule;
	require Exporter;
	@ISA = qw(Exporter);

becomes, with C<Exporter::VA>,

	package SomeModule;
	use Exporter::VA 1.1 ':normal';

The classic Exporter 

	@EXPORT_OK = qw/ foo bar /; # symbols to export on request

becomes with C<Exporter::VA>,

	%EXPORT= (
	   '.plain' => [ qw/ foo bar /];
	   # ...
	   };

The classic Exporter

	@EXPORT = qw/ baz quux /;  # symbols to export by default

becomes a tag named C<:DEFAULT>, thus:

	%EXPORT= (
	   '.plain' => [ qw/ :DEFAULT /];
	   ':DEFAULT' => [ qw/ foo bar / ];
	   };

and listing them as C<:DEFAULT> doesn't releive you from having define the individual
exports.  Using C<.plain> is the simplest way to define the exports, and note that you
don't have to re-list all of them, as it takes tag names too.

Likewise, any named tag is also listed as a key in the C<%EXPORT> list in this format.

=head2 Aliases and Non-Imported Calls

An alias specified in the C<%EXPORT> definition only works if it's imported.  For example,
if the C<%EXPORT> definition contained

	foo => [ v1.0, 'foo_old', v2.0, 'foo_new' ],
	bar => 'bar_internal',
	fobble => \&figure_it_out,

and the main program used:

	use ModuleName v1.5 qw(foo bar);

then the main code could call C<foo> and get C<ModuleName::foo_old>, and call C<bar> and
get C<ModuleName::bar_internal>.  But what happens if the main code explicitly calls
C<ModuleName::foo> or doesn't import at all, and tries to call C<ModuleName::fobble>?

It will indeed attempt to call functions named C<ModuleName::foo> and C<ModuleName::fobble>,
respectivly.  That is not the same as what happens when calling through the imported symbol.

To handle this, simply arrange it so there I<is> a function defined as C<ModuleName::foo> etc.

The best way to handle this is to assure that the directly-called functions have the identical semantics
as the imported aliases.

This can be handled automatically, by having C<ModuleName> import C<AUTOLOAD> from C<Exporter::VA>.
Then, a direct call to C<foo> will (if you don't happen to have an unrelated function called foo also!) land in
C<AUTOLOAD>, which will automatically generate a suitable C<ModuleName::foo>.  It will look up the
caller's desired version at run-time and jump to either C<foo_old> or C<foo_new> as appropreate.

If you need to write your own C<AUTOLOAD> for the module for other reasons, you can incorporate this
ability by calling the method L<autoload_symbol|autoload_symbol>.

If you don't like the automatically-generated thunk, you can easily create your own using the
underlying helper functions.  In order to write a function C<foo> that checks the caller's desired
version and calls the appropreate version, use the methods L<resolve|resolve> 
and L<VERSION|VERSION>.

There is no automatic facility to do this for non-functions.  You are better off using access methods instead
of direct access to data values.  But, you can accomplish much the same thing by using ties to a variable
of the stated name, where the tie's implementation switches between underlying versions.

If a data structure changes, instead of versioning the export for the data item, have the new version
remove the export of the data item and introduce an access method in its place.

=head2 Extending Exporter::VA

=head3 Using .&begin and .&end options

The easiest way to add some processing around this module's C<import> semantics is to use
the C<L<.&begin>> and L<C<.&end>> options.

=head3 Writing Your Own Import Function

It is simplest to import the implementation of C<import> from C<Exporter::VA>.
Anything you can do by wrapping it within a larger piece of code can be done using the C<L<.begin>> and C<L<.end>>
options.  You can also make changes by overriding various other methods in a derived class.  If you
do wish to write your own C<import> function, the generated one looks like this:

 	my $export_def; # found before function is generated
 	sub import 
 	 {
	 my $home= shift;
	 $export_def->setup ($home);  # happens first time used.
	 my $module= _calling_client();  # does caller() in a loop 'till out of Exporter::VA.
	 my $version= $export_def->get_import_version();
	 $export_def->callback ('.&begin', $module, $version, '.&begin', \@_);
	 @_ = ':DEFAULT'  if (!@_ && defined $export_def->{':DEFAULT'});
	 $export_def ->export ($module, $version, \@_);
	 $export_def->callback ('.&end', $module, $version, '.&begin', \@_);
	 $export_def->_process_worklist();
	 }

See this module's own L<pragmas|pragmas> for information on customizing this generated code without
rewriting it or cutting and pasting it.

=head3 The VERSION function

When a module uses C<Exporter::VA>, it typically imports a generated C<VERSION> function.  This makes the
versioning capabilities work, as C<ModuleName::VERSION> will not simply verify that the requested
version is less than the module's version, but will record the per-client desired version number for
subsequent use.

If the module doesn't import the generated C<VERSION> function from C<Exporter::VA>, then the versioning
features will not be available, and version numbers specified in C<use> statements will be silently
ignored by C<Exporter::VA>, since it will never see it.

=head3 Inheriting from Exporter::VA

This module is fundimentally designed to allow custimization via deriving from it.  However, the way it is
used is unique, and making it behave as an object needs a little explaining.

The C<import> function called by C<use> does not contain a this/self parameter, but only has the
list of imports.  In order to have all its helper functions make virtual calls and thus allow replacement,
an object is introduced as soon as possible.

The object is simply the C<%EXPORT> definition.  As you can see from the listing of C<import> above,
A reference to the C<%EXPORT> definition is blessed into C<Exporter::VA>, and
all subsequent functions are dispatched through it.

If you derive from C<Exporter::VA>, you must bless the object into your derived package instead, and
then your function overrides will be used.

Since C<import> has no object, it has the package name hard-coded into it.  If you derive from C<Exporter::VA>,
you I<could> supply the definition of C<import> from your derived class as well.  But if that's the only change
you need, you can use this module's own C<-derived> L<pragma|pragmas>.  This is an example of using
a pragmatic import to paramiterize the generation of an imported function.

	package Extend;
	use Exporter::VA ();
	@ISA= ('Exporter::VA');
	sub resolve { ... # override what I need to change here

	package ModuleName;
	use Exporter::VA qw/ -derived Extend  import AUTOLOAD /;
	%EXPORT= { ... #
	# proceed writing my module

=head2 Methods

=head3 autoload_symbol

	autoload_symbol ($blessed_export_def, $symbol, @extras)

Call this to implement C<AUTOLOAD>, or pre-generate the thunks.  Calling this will generate
a sub named C<$symbol> into the module where the C<$blessed_export_def> is from
that will redirect to the proper function based on its immediate caller at run-time.

Note that C<$symbol> must name a function listed in the C<%EXPORT> definition, and
you must <I>leave off</I> the '&' sigil.

Any extra arguments are passed as the C<$param_list_tail> if a callback is involved.  This
lets you pass parameters if need be, as would normally be found following the symbol name
in the import list.  However, it doesn't seem like a good idea to have ordinarily-named
import symbols taking parameters (they should begin with a dash, for clarity).

=head3 check_user_option

	$errormessage= check_user_option ($blessed_export_def, $optionname)

Supply this function in a derived class if you are adding any user-defined options.  If
checking is enabled, then any hash keys in the C<%EXPORT> definition that begin with a
C<.> or C<.&> followed by a capital letter are passed to this function for validation.

Return C<undef> if the option is OK, and no warning will be emitted.  Return a string
and it will be incorporated into the warning message.

The built-in base implementation will call the code in C<L<.check_user_option>> if
present, or otherwise report a warning on all parameters it checks.

=head3 dump

	dump ($blessed_export_def)

This prints a debug dump of the object to the C<VERBOSE> handle.  This might be handy to
call from your callbacks (or pragmatic imports) to see what's going on.  This is called by the
C<--dump> pragma.

=head3 export

	export ($blessed_export_def, $caller, $version, $item_or_list)

This will export a single item or a list of items.  C<$item_or_list> can be a single item (as from
an import list) or a reference to a whole list.  Each item is processed using the full rules
of the C<%EXPORT> definition.

You can call this from pragmatic callbacks or other places to explicitly export something at will.

The specified item(s) are resolved and then placed into the C<$caller>'s package.

=head3 find_export_def ($caller, $import_list)

Not virtual, but regular function.

This is used by C<import> to locate the C<%EXPORT> definition.  If it is found in the
C<$import_list>, it is removed from the list.  If not found in the list, then it looks for
the package global C<%EXPORT> in the C<$caller>.  Either way, it returns the hash ref.

You only need to call this yourself if implementing your own C<import>.

=head3 resolve

	$ref= resolve ($blessed_export_def, $caller, $version, $item, $import_param_tail)

This will look for C<$item> based on the C<%EXPORT> definition, and return a reference to the 
thing to export under that name based on the specified C<$version> and possibly the C<$caller>.  
The C<$caller> and C<$import_param_tail> are not needed directly, but will be passed to callbacks.

=head3 worklist

	$hashref= worklist ($blessed_export_def)

This return a reference to the I<work list>, used during the import list processing.

As each item in the import list is processed, the result doesn't get placed immediatly into
the caller's namespace.  Rather, it is added to this work list in the form C<< symbolname => ref >>.
This allows for subsequent pragmatic options or C<.&end> or future features to modify the list
before the work it represents is comitted.

TODO: decide how to keep the list ordered.

=head2 Exports

=head3 special

If a parameter to C<Exporter::VA>'s own C<import> is not a string but a hash ref, then it is
taken as the argument to the C<-def> pragma.

The package global file handle C<Exporter::VA::VERBOSE> is used for verbose-mode output
messages.  It is initially aliased to C<STDERR>, but may be redirected using glob assignment.

=head3 functions

=over 4

=item AUTOLOAD

=item import

=item normalize_vstring

This takes the argument which represents a version number, and returns a normalized form of it.
The normalized form allows for version comparisons using string relational operators, including
C<eq>.  That is, various ways of specifying the same version identifier are all converted to the
same canonocal form.  For example, C<v1.0>, C<"1.0.0.0">, C<1.0> all refer to the same
version and will return the same normalized string.

The following forms are accepted:

A string that is an ASCII representation of a dotted number is converted to a v-string.  If you
have a v-string that contains only values that happen to be ASCII digits and dots, such as
C<v51.46.50>, then it will think it's the ASCII string for C<"3.2"> and convert it to C<v3.2>.  To
disambiguate, add an extra C<.0> on the end, which does not change the meaning thanks to
normalization.  That is, C<v51.46.50.0> means the same thing as C<v51.46.50>.  Specifically
(and this is subject to change), any string that contains characters in the range of C<\x0> through
C<\x1f>, which are non-printable control codes, is considered to be a v-string.  A string that
contains no characters in this range is assumed to be a string representation of some kind.  Since
most version numbers are small, this is a natural way to distinguish them.

Using a float for a vstring 2.3 gives v2.3, not v2.300.  That is, it doesn't follow the 3-digit rule, but 
simple stringification.  Distinghishing a float literal from a string literal would require a module
not supplied with Perl 5.6 (but is available in 5.8).  Few people seem to use the 3-digit rule anyway.
It's best to just remember to always use the v, or use quotes.  In Perl 5.8 this may generate a warning
in the future.

After converting the input representation to a v-string, it is put into canonocal form to properly
allow C<eq> comparisons.  Specifically, trailing zeros are removed, except it will always have
at least two digits.  So C<v2> and C<v2.0.0.0.0.0.0> both become C<v2.0>.

This function is used by the module to allow version representations in your chosen format.  It
may be exported, so you can easily use this public function yourself, too.

=item VERSION

	$v= Module->VERSION;  # get version info
	Module->VERSION ($v);  # set/verify version info
	Module->VERSION ($v, $caller);  # set/verify version info for $caller
	$v= Module->VERSION (undef, $caller);  # get version info for $caller

The C<VERSION> function has a pre-defined meaning to Perl.  When a version number "indirect argument"
parameter is used, it is called as an argument to the Module's C<VERSION> function.  That function is intended
to die if the version is unsuitable.

Instead of simply checking that the supplied version is <= the Module's C<$VERSION>, this implementation
of C<VERSION> will note the version asked for by the caller.  This information is the basis for all features
that make use of knowing what version a module's client is expecting, such as to present different
import lists or enable backward-compatible behavior.

Besides noting the version, C<VERSION> still verifies it.  The desired version is still checked against the
upper-limit of the Module's C<$VERSION>, and the C<.allowed_VERSIONS> setting if present.

Unlike the supplied C<UNIVERSAL::VERSION>, this one can handle any supported format for the value of
C<$VERSION> (see C<L<normalize_vstring>>).

If called with no arguments, <VERSION> returns the Module's version.  It does this with caller awareness,
as different calling modules may have specified different versions of the use'd Module.  If you ask for
the version but never specified a desired version, it takes the module's C<$VERSION> (or the
C<.default_VERSION> setting), acting as though that was the version you asked for all along.

Note that it always returns a normalized v-string, regardless of what format you may have used
to set or specify the version.

So, this function is used internally by the semantics of use (or require) to set the per-module version,
and is also to obtain the per-module version for any (and all) need for this information.  If a function
within the module wants to know if it should emulate an old version or not, it can call its own VERSION
function and find out what the caller (first caller up the chain that's outside of this Module) is expecting.

As the sole interface for this information, the C<VERSION> function has one addional bit of flexibility.
You can call it with a 3rd argument to specify a client module, rather than using the caller.  So,

	package B;
	use Module v2.7;

	sub foo
	{
	my $B_version= Module->VERSION();  # gets v2.7
	my $Henry_version= Module->VERSION (undef, 'Henry');  # find out what Henry's doing.
	}

Note that you specify C<undef> as the version argument so that you can supply the 
optional extra argument and still use the "get" form of the function.  Presence of the 
version argument triggers the "set" form.

=back

=head3 tags

The tag C<:normal> will import the normal 3 functions, C<import>, C<AUTOLOAD>, and C<VERSION>.
This is not the C<:DEFAULT> on a matter of principle, that module writers are encouraged not to
export things by default and it is ironic to violate this in the exporter itself.

=head3 pragmas

=over 4

=item -def I<hashref>

This will supply the C<%EXPORT> definition, as opposed to having it found as a package global in
the caller.  You can leave off the C<-def> actually, and simply provide a hash ref argument
to import (via the C<use> statement).  The named pragma is provided for completeness sake.

	use ModuleName 0.2 (
		-def => \%myhash,
		qw/foo bar/
		);

As a special rule, this parameter may be located anywhere in the import list; it does not have
to come first, even though parameters are normally processed left-to-right.  This module goes
out of its way to do this because it is nicer to write it last, in producing readable code.

	use Exporter::VA ('import', 'VERSION', {
		foo => \\&internal_foo,
		bar => \\&internal_bar,
		# long list
		} );

You have the option of putting the regular parameters first, so they are not lost at the end of
the long literal hash.

=item -derived I<name>

The pragmatic import C<< -derived I<name> >> will customize the generated import function to contain
the specified I<name> as the package to bless the object into.  This is handy for deriving from C<Exporter::VA>.
For example:

	package ModuleName;
	use Exporter::VA qw/-derived ExpEnhancement import AUTOLOAD/;

note that this only affects items farther to the right in the list, so it makes sense to always put
C<-derived> first.

=item --dump

This will display the state of the C<%EXPORT> definition hash to the C<VERBOSE> file handle.  This
will include the items specified by the module doing the exporting, defaults expanded or filled in, and
internal state values.

=item --verbose_import

See L<.verbose|the .verbose setting>.  This increments the C<.verbose> value.

=back

=head1 Compatibility

=head2 Platforms

It uses only pure Perl and no non-basic modules, so it ought to work on any platform.  

I'd appreciate it if anyone using a different configuration (not listed below) let me know that the test1.perl
script works properly and that there are no issues.  If there are issues, I'm even more interested!

	Tested on:
	Exporter::VA version 1.3.0.1 on Perl 5.6.1 (AS 633, Windows 2000)
	Exporter::VA version 1.3.0.1 on Perl 5.8.0 (AS 804, Windows 2000)
	... others wanted!  CPAN testers haven't reported anything since I made the module compatible with CPANPLUS.

=head2 Unicode / utf8

In Perl 5.6, a compiled regex only works properly with strings of the same discipline (byte-oriented or
character oriented).  So, how should this module be compiled, with or without Unicode
regex's?  Since the strings being matched will be Perl identifier names, and non-ASCII identifiers
are only allowed when C<use utf8> is in effect, that is the natural choice.  Without utf8 mode, you
have no business importing a symbol that contains a Unicode name, anyway.  Note that if you do pass
byte-oriented strings to the C<import()> function that contain values >127, you'll get warnings about
bad UTF-8 encoding from the module.  Don't do that.  You have no business using such characters in
identifier names, and you'll have to work-around that for pragmatic import names beginning with a
dash (which don't have to be legal identifiers).  The regex issue is fixed in Perl 5.8, so it is no longer
a problem moving forward.

=head2 Threads

The Exporter::VA module is oblivious to threads.  Modules are normally imported at the beginning
of execution before threads are started, so there is not much incentive to verify the matter.  But if
you do call C<import()> for the same module from two different threads, the C<%EXPORT> definition
should be copied to each thread.  As of writing, I'm unaware of how symbol tables are shared (or not).
Anyone who explores the matter or stresses the module in this regard, please let me know.

=head1 Caveats and known issues

=head2 not implemented

-derived pragma not implemented yet.

=head2 not tested

Not in unit test: check_user_option() semantics.

Not in unit test: warnings if typo in export definition.

Not in unit test: extra arguments to C<autoload_symbol> passed to callback in C<%EXPORT> definition.
Don't do that anyway!

=head1 Ideas for Future

Allow tags to be callbacks.  That could support a dynamic :all tag, as well as dynamic lists in general.
You can manage it now with some effort... a pragmatic import calls export() itself to export a whole
list of things, and if you really want the tag syntax, define a tag that expands to that one pragma.

Allow tag's definition to contain other tags, not just symbols.

=head1 COPYRIGHT

 Copyright 2003 by John M. Dlugosz. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=head1 HISTORY

See the README.txt file for detailed history.

