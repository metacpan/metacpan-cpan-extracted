package Devel::Kit;

use strict;
use warnings;

use Module::Want 0.6 ();
use String::UnicodeUTF8 ();

$Devel::Kit::VERSION = '0.81';
$Devel::Kit::fh      = \*STDOUT;

my $pid;

sub import {
    my $caller = caller();

    my $pre = '';
    for (@_) {
        if ( $_ =~ m/(_+)/ ) {
            $pre = $1;
            last;
        }
    }

    no strict 'refs';    ## no critic
    for my $l (qw(a d ei rx ri ni ci si yd jd xd sd md id pd fd dd ld ud gd bd vd ms ss be bu ce cu xe xu ue uu he hu pe pu se su qe qu)) {
        *{ $caller . '::' . $pre . $l } = \&{$l};
    }

    unless ( grep( m/no/, @_ ) ) {
        require Import::Into;    # die here since we don't need it otherwise, so we know right off there's a problem, and so caller does not have to check status unless they want to
        strict->import::into($caller);
        warnings->import::into($caller);
    }
}

my $ak;

sub a {
    if ( !$ak ) {
        require App::Kit;
        $ak = App::Kit->instance;
    }
    return $ak;
}

# output something w/ one trailing newline gauranteed
sub o {
    my ($str) = @_;
    $str =~ s{[\n\r]+$}{};
    print {$Devel::Kit::fh} "$str\n";
}

# dump a perl ref()
sub p {
    my $ref = ref( $_[0] );

    if ( !$ref ) {
        if ( !@_ ) {
            return "no args passed to p()";
        }
        elsif ( !defined $_[0] ) {
            return "undef() passed to p()";
        }
        elsif ( $_[0] eq '' ) {
            return "empty string passed to p()";
        }
        else {
            return "non-ref passed to p(): $_[0]";
        }
    }

    if ( $ref eq 'Regexp' ) {
        return "\tRegexp: /$_[0]/";
    }
    elsif ( Module::Want::have_mod('Data::Dumper') ) {

        # blatantly stolen from Test::Builder::explain() then wantonly added Pad()
        my $dumper = Data::Dumper->new( [ $_[0] ] );
        $dumper->Indent(1)->Terse(1)->Pad("\t");
        $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
        return $dumper->Dump;
    }
    else {
        return "Error: “Data::Dumper” could not be loaded:\n\t$@\n";
    }
}

sub d {
    my @caller = caller();

    if ( !@_ ) {
        o("debug() w/ no args at $caller[1] line $caller[2].");
        return;
    }

    my $arg_index = @_ > 1 ? -1 : undef();
    my $i;    # buffer
    for $i (@_) {    ## no critic
        $arg_index++ if defined $arg_index;
        my $arg_note = defined $arg_index ? $arg_index : '';

        if ( ref($i) ) {
            o( "debug($arg_note) ref($i) at $caller[1] line $caller[2]:\n" . p($i) );
        }
        elsif ( !defined $i ) {
            o("debug($arg_note) undef at $caller[1] line $caller[2].");
        }
        elsif ( $i eq '' ) {
            o("debug($arg_note) empty at $caller[1] line $caller[2].");
        }
        elsif ( $i =~ m/\A-?[1-9][0-9]*(?:\.[0-9]+)?\z/ ) {    # we're not that worried about matching every possible numeric looking thing so no need to spend on looks_like_number()
            o("debug($arg_note) number: $i");
        }
        else {
            o("debug($arg_note): $i");
        }
    }

    return;
}

sub ei {
    my $ret = defined $_[-1] && $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    my ($more) = @_;
    $more ||= 0;

    my $cwd = Module::Want::have_mod('Cwd') ? Cwd::cwd() : '??? (Cwd.pm missing)';
    my $res = "Environment:\nPerl: v$]\nPID : $$\n\$0  : $0\n\$^X : $^X\nCWD : $cwd\nRUID: $<\nEUID: $>\nRGID: $(\nEGID: $)\n\@INC:\n" . p( \@INC );

    if ( Module::Want::have_mod('Unix::PID::Tiny') ) {
        $pid ||= Unix::PID::Tiny->new();
        $res .= "Proc:\n" . p( { $pid->pid_info_hash($$) } );
    }
    else {
        $res .= "Error: “Unix::PID::Tiny” could not be loaded:\n\t$@\n";
    }

    if ( $more ne '_Devel::Kit_return' && ( $more == 1 || $more == 2 ) ) {
        $res .= "\%ENV:\n" . p( \%ENV );
    }

    if ( $more ne '_Devel::Kit_return' && $more == 2 ) {
        if ( Module::Want::have_mod('Config') ) {

            no warnings 'once';
            $res .= "\%Config:" . p( \%Config::Config );
        }
        else {
            $res .= "Error: “Config” could not be loaded:\n\t$@\n";
        }
    }

    @_ = $res;
    return @_ if $ret;
    goto &d;
}

sub rx {
    if ( Module::Want::have_mod('Regexp::Debugger') ) {

        # can't just rxrx() here due to CHECK voodoo in Regexp::Debugger
        system( $^X, '-MRegexp::Debugger', '-e', 'Regexp::Debugger::rxrx(@ARGV)', @_ );
    }
    else {
        d("Error: “Regexp::Debugger” could not be loaded:\n\t$@\n");
    }
}

sub ri {
    my @caller = caller();
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = "debug($_[0]) at $caller[1] line $caller[2]:\n" . p( $_[0] ) . _devel_info( $_[0] );

    return @_ if $ret;
    goto &d;
}

sub ni {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    if ( Module::Want::is_ns( $_[0] ) ) {
        my $verbose  = ( defined $_[1] && $_[1] eq '_Devel::Kit_return' ? 0 : $_[1] );
        my $inc_path = Module::Want::get_inc_path_via_have_mod( $_[0] );
        my $inc_err  = $@;

        @_ =
            "$_[0]\n"
          . "\tNormalized: "
          . Module::Want::normalize_ns( $_[0] ) . "\n"
          . "\tDist Name : "
          . Module::Want::ns2distname( $_[0] ) . "\n"
          . "\tINC Key   : "
          . Module::Want::get_inc_key( $_[0] ) . "\n"
          . "\tINC Value : "
          . ( $inc_path || "“$_[0]” is not loadable:\n\t\t$inc_err" ) . "\n"
          . ( $inc_path ? "\tVersion   : " . $_[0]->VERSION . "\n" : '' )
          . ( $inc_path && $verbose ? "\tClass Info:\n" . _ns_info( Module::Want::normalize_ns( $_[0] ), ( $verbose == 2 ? 1 : 0 ) ) : '' );
    }
    else {
        @_ = "Error: ni() requires a name space\n";
    }

    return @_ if $ret;
    goto &d;
}

sub si {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? pop(@_) : 0;

    @_ = _at_setup(
        'IPC::Open3::Utils',
        sub {
            my $out = "Command: \n" . p( \@_ ) . "\n";

            my $open3_error;
            if (
                !IPC::Open3::Utils::run_cmd(
                    @_,
                    {
                        'open3_error' => \$open3_error,
                        'handler'     => sub {
                            my ( $cur_line, $stdin, $is_stderr, $is_open3_err, $short_circuit_loop_boolean_scalar_ref ) = @_;
                            $out .= $is_stderr ? "  STDERR: $cur_line" : "  STDOUT: $cur_line";
                            return 1;
                        },
                    }
                )
              ) {
                $out .= "Command did not exit cleanly:\n";
                $out .= "  \$? = $?\n  \$! = " . int($!) . " ($!)\n";
                if ($open3_error) {
                    chomp($open3_error);
                    $out .= "  open3() said: $open3_error\n";
                }

                if ($?) {    # or if (!child_error_ok($?)) {
                    $out .= "  Command failed to execute.\n" if IPC::Open3::Utils::child_error_failed_to_execute($?);
                    $out .= "  Command seg faulted.\n"       if IPC::Open3::Utils::child_error_seg_faulted($?);
                    $out .= "  Command core dumped.\n"       if IPC::Open3::Utils::child_error_core_dumped($?);
                    unless ( IPC::Open3::Utils::child_error_failed_to_execute($?) ) {
                        $out .= "  Command exited with signal: " . IPC::Open3::Utils::child_error_exit_signal($?) . ".\n";
                        $out .= "  Command exited with value: " . IPC::Open3::Utils::child_error_exit_value($?) . ".\n";
                    }
                }
            }
            else {
                $out .= "Command exited cleanly.\n";
                $out .= "  \$? = $?\n  \$! = " . int($!) . " ($!)\n";
            }

            return $out;
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub ci {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    if ( Module::Want::have_mod('Devel::Kit::_CODE') ) {
        my $verbose = ( defined $_[1] && $_[1] eq '_Devel::Kit_return' ? 0 : $_[1] );
        @_ = Devel::Kit::_CODE::_cd( $_[0], $verbose );
    }
    else {
        @_ = "Error: “Devel::Kit::_CODE” could not be loaded:\n\t$@\n";
    }

    return @_ if $ret;
    goto &d;
}

# YAML Dumper
sub yd {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'YAML::Syck',
        sub {
            eval { YAML::Syck::Load( $_[0] ); } || "Error: Invalid YAML ($@):\n$_[0]";
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

# JSON Dumper
sub jd {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'JSON::Syck',
        sub {
            eval { JSON::Syck::Load( $_[0] ); } || "Error: Invalid JSON ($@):\n$_[0]";
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

# XML Dumper
my $xml;

sub xd {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'XML::Parser',
        sub {
            $xml ||= XML::Parser->new(
                'Style'            => 'Tree',
                'ProtocolEncoding' => 'UTF-8',
            );

            eval { $xml->parsestring( $_[0] ); } || "Error: Invalid XML ($@):\n$_[0]";
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

# Storable Dumper
sub sd {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'Storable',
        sub {
            eval { Storable::thaw( $_[0] ); } || "Error: Invalid Storable ($@):\n$_[0]";
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

# INI dump
sub id {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'Config::INI::Reader',
        sub {
            eval { Config::INI::Reader->read_string( $_[0] ); } || "Error: Invalid INI ($@):\n$_[0]";
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

# Message Pack dump
my $mp;

sub md {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'Data::MessagePack',
        sub {
            $mp ||= Data::MessagePack->new();

            eval { $mp->unpack( $_[0] ); } || "Error: Invalid MessagePack ($@):\n$_[0]";
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

# Perl Dumper (e.g. Data::Dumper, Data::Dump, etc.)
sub pd {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    no strict;    ## no critic
    @_ = eval( $_[0] ) || "Error: Invalid perl ($@):\n$_[0]";    ## no critic

    return @_ if $ret;
    goto &d;
}

# File dump
sub fd {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    if ( !-l $_[0] && -f _ ) {
        if ( Module::Want::have_mod('File::Slurp') ) {
            my $info   = _stat_struct( $_[0] );
            my $line_n = 0;
            my @lines  = eval { File::Slurp::read_file( $_[0] ) };
            if ($@) {
                $info->{"13. contents"} = "Error: read_file() failed ($@)";
            }
            else {
                $info->{"13. contents"} = [ map { ++$line_n; my $l = $_; chomp($l); "$line_n: $l" } @lines ];
            }

            @_ = (
                {
                    "File “$_[0]”:" => $info,
                }
            );
        }
        else {
            @_ = ("Error: “File::Slurp” could not be loaded:\n\t$@\n");
        }
    }
    elsif ( !-e _ ) {
        @_ = ("“$_[0]” does not exist.");
    }
    else {
        @_ = ("“$_[0]” is not a file.");
    }

    return @_ if $ret;
    goto &d;
}

# Directory dump
sub dd {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    if ( !-l $_[0] && -d _ ) {

        if ( Module::Want::have_mod('File::Slurp') ) {
            my $info = _stat_struct( $_[0] );
            my $list_ar = scalar( eval { File::Slurp::read_dir( $_[0] ) } );
            if ($@) {
                $info->{"13. contents"} = "Error: read_dir() failed ($@)";
            }
            else {
                $info->{"13. contents"} = $list_ar;
            }

            @_ = (
                {
                    "Directory “$_[0]”:" => $info,
                }
            );
        }
        else {
            @_ = ("Error: “File::Slurp” could not be loaded:\n\t$@\n");
        }
    }
    elsif ( !-e _ ) {
        @_ = ("“$_[0]” does not exist.");
    }
    else {
        @_ = ("“$_[0]” is not a directory.");
    }

    return @_ if $ret;
    goto &d;
}

# Symlink dump
sub ld {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    if ( -l $_[0] ) {
        my $info = _stat_struct( $_[0] );
        $info->{"13. target"} = readlink( $_[0] );
        $info->{"14. broken"} = -l $info->{"13. target"} || -e _ ? 0 : 1;

        @_ = (
            {
                "Symlink “$_[0]”:" => $info,
            }
        );
    }
    elsif ( !-e _ ) {
        @_ = ("“$_[0]” does not exist.");
    }
    else {
        @_ = ("“$_[0]” is not a symlink.");
    }

    return @_ if $ret;
    goto &d;
}

# Unicode string dumper
sub ud {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;
    @_ = ( "Unicode: " . String::UnicodeUTF8::escape_unicode( $_[0] ) );

    return @_ if $ret;
    goto &d;
}

# bytes grapheme dumper
sub gd {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;
    @_ = ( "Bytes grapheme: " . String::UnicodeUTF8::escape_utf8( $_[0] ) );

    return @_ if $ret;
    goto &d;
}

# bytes string viewer
sub bd {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;
    @_ = ( "Bytes: " . String::UnicodeUTF8::get_utf8( $_[0] ) );

    return @_ if $ret;
    goto &d;
}

# Verbose/Variation of a string dump
sub vd {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    my ($s) = @_;

    my $verbose = ( defined $_[1] && $_[1] eq '_Devel::Kit_return' ? 0 : $_[1] );

    @_ = (

        # tidy off
        _trim_label( bd( $s, '_Devel::Kit_return' ) ) . "\n"    # "$s\n"
          . "\tOriginal string type: "
          . ( String::UnicodeUTF8::is_unicode($s) ? 'Unicode' : 'Byte' ) . "\n"
          . "\tSize of data (bytes): "
          . String::UnicodeUTF8::bytes_size($s) . "\n"
          . "\tNumber of characters: "
          . String::UnicodeUTF8::char_count($s) . "\n"
          . ( $verbose ? _devel_info($s) : '' ) . "\n"
          . "\tUnicode Notation Str: "
          . _trim_label( ud( $s, '_Devel::Kit_return' ) ) . "\n"
          . "\tBytes Grapheme Str  : "
          . _trim_label( gd( $s, '_Devel::Kit_return' ) ) . "\n"
          . "\tBytes String        : "
          . _trim_label( bd( $s, '_Devel::Kit_return' ) ) . "\n" . "\n"
          . "\tMD5 Sum  : "
          . _trim_label( ms( $s, '_Devel::Kit_return' ) ) . "\n"
          . "\tSHA1 Hash: "
          . _trim_label( ss( $s, '_Devel::Kit_return' ) ) . "\n" . "\n"
          . "\tBase 64    : "
          . _trim_label( be( $s, '_Devel::Kit_return' ) ) . "\n"
          . "\tCrockford  : "
          . _trim_label( ce( $s, '_Devel::Kit_return' ) ) . "\n"
          . "\tHex        : "
          . _trim_label( xe( $s, $verbose, '_Devel::Kit_return' ) ) . "\n"
          . "\tURI        : "
          . _trim_label( ue( $s, '_Devel::Kit_return' ) ) . "\n"
          . "\tHTML       : "
          . _trim_label( he( $s, '_Devel::Kit_return' ) ) . "\n"
          . "\tQuot-Print : "
          . _trim_label( qe( $s, '_Devel::Kit_return' ) ) . "\n"
          . "\tPunycode   : "
          . _trim_label( pe( $s, '_Devel::Kit_return' ) ) . "\n"

          # . "\tString Lit : "
          # . _trim_label( se( $s, '_Devel::Kit_return' ) ) . "\n"

          # tidy on
    );

    return @_ if $ret;
    goto &d;
}

# Serialize, Sum, haSh,

sub ms {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'Digest::MD5',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "MD5 Sum: " . Digest::MD5::md5_hex($s);
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub ss {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'Digest::SHA',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "SHA1 Hash: " . Digest::SHA::sha1_hex($s);
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

# Encode/Unencode Escape/Unescape

sub be {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'MIME::Base64',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "Base 64: " . MIME::Base64::encode_base64( $s, '' );
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub bu {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'MIME::Base64',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "From Base 64: " . MIME::Base64::decode_base64($s);
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub ce {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'Convert::Base32::Crockford',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "Crockford: " . Convert::Base32::Crockford::encode_base32($s);
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub cu {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'Convert::Base32::Crockford',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "From Crockford: " . Convert::Base32::Crockford::decode_base32($s);
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub xe {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    my $verbose = ( defined $_[1] && $_[1] eq '_Devel::Kit_return' ? 0 : $_[1] );

    if ($verbose) {
        @_ = "Hex: " . p(
            [
                map {
                    my $c = String::UnicodeUTF8::get_utf8($_);
                    "$c : " . unpack( "H*", $c );
                } split( '', String::UnicodeUTF8::get_unicode( $_[0] ) )
            ]
        );
        $_[0] =~ s/^\s*//;
    }
    else {
        @_ = "Hex: " . unpack( "H*", String::UnicodeUTF8::get_utf8( $_[0] ) );
    }

    return @_ if $ret;
    goto &d;
}

sub xu {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = "From Hex: " . pack 'H*', $_[0];

    return @_ if $ret;
    goto &d;
}

sub ue {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'URI::Escape',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "URI: " . URI::Escape::uri_escape($s);
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub uu {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'URI::Escape',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "From URI: " . URI::Escape::uri_unescape($s);
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub he {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'HTML::Entities',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "HTML Safe: " . HTML::Entities::encode( $s, q{<>&"'} );
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub hu {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'HTML::Entities',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "From HTML Safe: " . HTML::Entities::decode($s);
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub qe {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'MIME::QuotedPrint',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "Quoted-Printable: " . MIME::QuotedPrint::encode($s);
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub qu {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'MIME::QuotedPrint',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            return "From Quoted-Printable: " . MIME::QuotedPrint::decode($s);
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub pe {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'Net::IDN::Encode',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            my $res;

            # See Locale::Maketext::Utils::output_encode_puny()
            if ( $s =~ m/(?:\@|\xef\xbc\xa0|\xef\xb9\xab)/ ) {    # U+0040, U+FF20, and U+FE6B, no need for U+E0040 right?
                my ( $nam, $dom ) = split( /(?:\@|\xef\xbc\xa0|\xef\xb9\xab)/, $s, 2 );    # multiple @ == ???
                utf8::decode($nam);                                                        # turn utf8 bytes into a unicode string
                utf8::decode($dom);                                                        # turn utf8 bytes into a unicode string
                eval { $res = Net::IDN::Encode::domain_to_ascii($nam) . '@' . Net::IDN::Encode::domain_to_ascii($dom); };
                $res = "invalid string for punycode ($@)" if $@;
            }
            else {
                utf8::decode($s);                                                          # turn utf8 bytes into a unicode string
                eval { $res = Net::IDN::Encode::domain_to_ascii($s); };
                $res = "invalid string for punycode ($@)" if $@;
            }

            return "Punycode: " . $res;
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub pu {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = _at_setup(
        'Net::IDN::Encode',
        sub {
            my ($s) = $_[0];
            $s = String::UnicodeUTF8::get_utf8($s);
            my $res;

            # See Locale::Maketext::Utils::output_decode_puny()
            if ( $s =~ m/\@/ ) {
                my ( $nam, $dom ) = split( /@/, $s, 2 );    # multiple @ == ???
                eval { $res = Net::IDN::Encode::domain_to_unicode($nam) . '@' . Net::IDN::Encode::domain_to_unicode($dom); };
                if ($@) {
                    $res = "invalid punycode ($@)";
                }
                else {
                    utf8::encode($res);                     # turn unicode string back into utf8 bytes
                }
            }
            else {
                eval { $res = Net::IDN::Encode::domain_to_unicode($s); };
                if ($@) {
                    $res = "invalid punycode ($@)";
                }
                else {
                    utf8::encode($res);                     # turn unicode string back into utf8 bytes
                }
            }
            return "From Punycode: " . $res;
        },
        @_
    );

    return @_ if $ret;
    goto &d;
}

sub se {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = "Given: $_[0]\n\n\t" . q{my $bytes = "} . String::UnicodeUTF8::quotemeta_bytes( $_[0] ) . qq{";\n\n\t} . q{my $utf8 = "} . String::UnicodeUTF8::quotemeta_utf8( $_[0] ) . qq{";\n\n\t} . q{my $unicode = "} . String::UnicodeUTF8::quotemeta_unicode( $_[0] ) . qq{";\n};

    return @_ if $ret;
    goto &d;
}

sub su {
    my $ret = $_[-1] eq '_Devel::Kit_return' ? 1 : 0;

    @_ = "Given: $_[0]\n\tRenders: " . String::UnicodeUTF8::unquotemeta_bytes( $_[0] );

    return @_ if $ret;
    goto &d;
}

sub _at_setup {
    return if @_ == 2;    # 'no args' instead of 'undef'

    if ( !defined $_[2] || $_[2] eq '' || ref $_[2] ) {
        @_ = $_[2];
    }
    elsif ( Module::Want::have_mod( $_[0] ) ) {
        @_ = $_[1]->( @_[ 2 .. $#_ ] );
    }
    else {
        @_ = "Error: “$_[0]” could not be loaded:\n\t$@\n";
    }

    return @_;
}

sub _trim_label {
    my ($s) = @_;
    $s =~ s/^[^:]+:\s*//;
    return $s;
}

sub _stat_struct {
    my @s = -l $_[0] ? lstat( $_[0] ) : stat( $_[0] );

    return {
        ' 0. dev'     => $s[0],
        ' 1. ino'     => $s[1],
        ' 2. mode'    => $s[2],
        ' 3. nlink'   => $s[3],
        ' 4. uid'     => $s[4],
        ' 5. gid'     => $s[5],
        ' 6. rdev'    => $s[6],
        ' 7. size'    => $s[7],
        ' 8. atime'   => $s[8],
        ' 9. mtime'   => $s[9],
        '10. ctime'   => $s[10],
        '11. blksize' => $s[11],
        '12. blocks'  => $s[12],
    };
}

sub _devel_info {
    my $string = '';
    if ( Module::Want::have_mod('Devel::Size') ) {
        $string = "\tDevel::Size:\n\t\tsize() " . Devel::Size::size( $_[0] ) . "\n" . "\t\ttotal_size() " . Devel::Size::total_size( $_[0] ) . "\n";
    }
    if ( Module::Want::have_mod('Devel::Peek') && Module::Want::have_mod('Capture::Tiny') ) {
        my $peek = Capture::Tiny::capture_stderr( sub { Devel::Peek::Dump( $_[0] ) } );
        $peek =~ s/\n/\n\t\t/msg;
        $peek =~ s/\n\t\t$//;
        chomp($peek);
        $string .= "\tDevel::Peek:\n\t\t$peek" . "\n";
    }
    return $string;
}

sub _ns_info {
    my ( $ns, $verbose_ci ) = @_;
    $verbose_ci = $verbose_ci ? ',1' : '';

    my $have_dcp = Module::Want::have_mod('Devel::CountOps');
    my $have_ct  = Module::Want::have_mod('Capture::Tiny');

    if ( $have_dcp && $have_ct ) {
        my $inc = "\t\tAdds to INC:\n" . `perl -M$ns -e 'for my \$k (sort keys %INC) {print "\\t\\t\\t\$k\\n"}'`;

        my $kit_lib = $INC{"Devel/Kit.pm"};
        $kit_lib =~ s{/Devel/Kit.pm$}{};    # ick, use File::Spec

        my $use = Capture::Tiny::capture_merged( sub { system(qq{$^X -I$kit_lib -mDevel::CountOps -MDevel::Kit -e 'ci(sub { eval "use $ns;1" or die \$@ }$verbose_ci)'}); } );
        $use =~ s/.*debug\(\): CODE\(.*?\n//ms;
        $use =~ s/\n/\n\t\t\t/msg;
        $use =~ s/\n\t\t\t$//;
        chomp($use);

        my $noi = Capture::Tiny::capture_merged( sub { system(qq{$^X -I$kit_lib -mDevel::CountOps -MDevel::Kit -e 'ci(sub { eval "use $ns ();1" or die \$@ }$verbose_ci)'}); } );
        $noi =~ s/.*debug\(\): CODE\(.*?\n//ms;
        $noi =~ s/\n/\n\t\t\t/msg;
        $noi =~ s/\n\t\t\t$//;
        chomp($noi);

        my $req = Capture::Tiny::capture_merged( sub { system(qq{$^X -I$kit_lib -mDevel::CountOps -MDevel::Kit -e 'ci(sub { eval "require $ns;1" or die \$@ }$verbose_ci)'}); } );
        $req =~ s/.*debug\(\): CODE\(.*?\n//ms;
        $req =~ s/\n/\n\t\t\t/msg;
        $req =~ s/\n\t\t\t$//;
        chomp($req);

        return $inc . "\t\tuse $ns;\n\t\t\t$use\n\t\tuse $ns ();\n\t\t\t$noi\n\t\trequire $ns;\n\t\t\t$req\n";
    }
    else {
        return "\t\tPlease install Capture::Tiny and Devel::CountOp.\n" if !$have_dcp && !$have_ct;
        return "\t\tPlease install Devel::CountOp.\n"                   if !$have_dcp;
        return "\t\tPlease install Capture::Tiny.\n"                    if !$have_ct;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Devel::Kit - Handy toolbox of things to ease development/debugging.

=head1 VERSION

This document describes Devel::Kit version 0.81

=head1 SYNOPSIS

    use Devel::Kit; # strict and warnings are now enabled

    d($something); # d() and some other useful debug/dump functions are now availble!

    perl -e 'print @ARGV[0];' # no warning
    perl -e 'print $x;' # no strict error

    perl -MDevel::Kit -e 'print @ARGV[0];'# issues warnings: Scalar value @ARGV[0] better written as $ARGV[0] …
    perl -MDevel::Kit -e 'print $x;' # Global symbol "$x" requires explicit package name …

    perl -MDevel::Kit -e 'd();d(undef);d("");d(1);d("i got here");d({a=>1},[1,2,3],"yo",\"howdy");ud("I \x{2665} perl");bd("I \xe2\x99\xa5 perl");gd("I ♥ perl");'

See where you are or are not getting to in a program and why, for example via this pseudo patch:

    + d(1);
    + d(\$foo);

    bar();

    if ($foo) {
    +    d(2);
        …
    }
    else {
    +    d(3);
        …
    }
    + d(4);

If it outputs 1, $foo’s true value, 3,4 you know to also dump $foo after bar() since it acts like bar() is modifying $foo (action at a distance). If $foo is false after the call to bar() then you can add debug statements to bar() to see where specifically $foo is fiddled with.

Visually see if a string is a byte string or a Unicode string:

    perl -MDevel::Kit -e 'd(\$string);'

If it is a Unicode string the \x{} codepoint notation will be present, if it is a byte string it will not be present:

    [dmuey@multivac ~]$ perl -MDevel::Kit -e 'd(\"I \x{2665} perl");'
    debug() ref(SCALAR(0x100804fc0)) at -e line 1:
        \"I \x{2665} perl"
    [dmuey@multivac ~]$ perl -MDevel::Kit -e 'd(\"I ♥ perl");'
    debug() ref(SCALAR(0x100804fc0)) at -e line 1:
        \'I ♥ perl'
    [dmuey@multivac ~]$ perl -MDevel::Kit -e 'd(\"I \xe2\x99\xa5 perl");'
    debug() ref(SCALAR(0x100804fc0)) at -e line 1:
        \'I ♥ perl'
    [dmuey@multivac Devel-Kit]$ perl -Mutf8 -MDevel::Kit -e 'd(\"I ♥ perl");'
    debug() ref(SCALAR(0x100804ff0)) at -e line 1:
    	\"I \x{2665} perl"
    [dmuey@multivac Devel-Kit]$

=head1 DESCRIPTION

From one line data dumping sanity checks to debug print statements in a large body of code I often found myself reinventing these basic solutions.

Hence this module was born to help give a host of functions/functionality with a minimum of typing/effort required.

Any modules required for any functions are lazy loaded if needed so no need to manage use statements!

=head1 SHELL ALIAS

This is a handy alias I put in my shells’ profile/rc file(s) to make short debug/test commands even shorter!

    alias pkit='perl -MDevel::Kit'

Then you can run:

    pkit -e 'vd("I ♥ perl");'
    pkit -Mutf8 -e 'vd("I ♥ perl");'

To get a better ci():

    alias pkit_ops='perl -mDevel::CountOps -MDevel::Kit'

=head1 (TERSE) INTERFACE

You'll probably note that every thing below is terse (i.e. not ideally named for maintenance).

That is on purpose since this module is meant for one-liners and development/debugging: NOT for production.

=head2 strict/warnings

import() enables strict and warnings in the caller unless you pass the string “no” to import().

    use Devel::Kit; # as if you had use strict;use warnings; here
    use Devel::Kit qw(no); # no strict/warnings

    perl -MDevel::Kit -e 'print @ARGV[0];print $x;' # triggers strict/warnings
    perl -MDevel::Kit=no -e 'print @ARGV[0];print $x;' # no strict/warnings happen

=head2 imported functions

If you already have a function by these names you can pass "_" to import() which will import them all w/ an underscore prepended. You can pass "__" to have it prepend 2, "___" to prepend 3, ad infinitum.

=head3 a() App::Kit

You can get a lazy loaded and reused L<App::Kit> object via a().

    pkit -e 'd( a->ctype->get_ctype_of_ext(".pm") )'

=head3 d() General debug/dump

Takes zero or more arguments to do debug info on.

The arguments can be a scalar or any perl reference you like.

It’s output is handled by L</Devel::Kit::o()> and references are stringified by L</Devel::Kit::p()>.

=head3 Perly Info dumpers

=head4 ci() coderef stat info

Runs the given code ref and takes some measurements.

    perl -MDevel::Kit -e 'ci(sub {…})'
    perl -MDevel::Kit -e 'ci(sub {…},1)' # … also include a diff of the symbol table before and after running

Caveat: Observer effect

Some things might not be apparent due the current state of things. For example, a module might be loaded by the coderef but since it is already loaded it is not factored in the results.

Caveat: You get more accurate results if Devel::CountOps is loaded during BEGIN before you call ci()

You could use the pkit_ops alias or -mDevel::CountOps first:

    perl -mDevel::CountOp -MDevel::Kit -e 'ci(sub {…})'

=head4 ni() name space info

    perl -MDevel::Kit -e 'ni('Foo::Bar')'
    perl -MDevel::Kit -e 'ni('Foo::Bar',1)' # … also include ci() info (via system() to cut down on the 2 caveats noted for ci())
    perl -MDevel::Kit -e 'ni('Foo::Bar',2)' # … also include verbose ci() info (via system() to cut down on the 2 caveats noted for ci())

=head4 ei() environment info

    perl -MDevel::Kit -e 'ei()'
    perl -MDevel::Kit -e 'ei(1)' # … also dump %ENV
    perl -MDevel::Kit -e 'ei(2)' # … also dump %Config

=head4 ri() ref info

like Devel::Kit::p() but w/ Devel::Size and/or Devel::Peek info as well

    perl -MDevel::Kit -e 'ri($your_ref_here)'

=head4 si() system command info

    perl -MDevel::Kit -e 'si(@system_cmd)'

Execute’s @system_cmd, displays its output labeled as STDOUT/STDERR, and describes its child error and errno states.

Currently there is no interface to the command’s STDIN but it could be added, let me know if you’d find that useful.

=head4 rx() interactive Regex debugging

Lazy loaded Regexp::Debugger::rxrx() wrapper. See L<Regexp::Debugger> for more info.

    perl -MDevel::Kit -e 'rx()'

=head3 Data Format dumpers

If a function ends in “d” it is a dumper. Each takes one argument, the string in the format we’re dumping.

Like d() it’s output is handled by L</Devel::Kit::o()> and references are stringified by L</Devel::Kit::p()>.

=head4 yd() YAML dumper

    perl -MDevel::Kit -e 'yd($your_yaml_here)'

=head4 jd() JSON dumper

    perl -MDevel::Kit -e 'jd($your_json_here)'

=head4 xd() XML dumper

    perl -MDevel::Kit -e 'xd($your_xml_here)'

=head4 sd() Storable dumper

    perl -MDevel::Kit -e 'sd($your_storable_here)'

=head4 id() INI dumper

    perl -MDevel::Kit -e 'id($your_ini_here)'

=head4 md() MessagePack dumper

    perl -MDevel::Kit -e 'md($your_message_pack_here)'

=head4 pd() Perl (stringified) dumper

    perl -MDevel::Kit -e 'pd($your_stringified_perl_structure_here)'

=head3 File system

These dump information about the path given.

=head4 fd() File dumper

    perl -MDevel::Kit -e 'fd($your_file_here)'

=head4 dd() Directory dumper

    perl -MDevel::Kit -e 'dd($your_directory_here)'

=head4 ld() Link dumper (i.e. symlinks)

    perl -MDevel::Kit -e 'ld($your_symlink_here)'

=head3 String Representations

These can take a utf-8 or Unicode string and show the same string as the type being requested.

=head4 ud() Unicode string dumper

    perl -MDevel::Kit -e 'ud($your_string_here)'

=head4 bd() Byte string utf-8 dumper

    perl -MDevel::Kit -e 'bd($your_string_here)'

=head4 gd() Grapheme byte string utf-8 dumper

    perl -MDevel::Kit -e 'gd($your_string_here)'

=head4 vd() Verbose Variations of string dumper

    perl -MDevel::Kit -e 'vd($your_string_here)'

    perl -MDevel::Kit -e 'vd($your_string_here, 1)' # verbose flag shows Devel::Size and/or Devel::Peek info as possible

=head3 Serialize/Sum/haSh

Unicode strings are turned into utf-8 before summing (since you can’t sum a Unicode string)

=head4 ms() MD5

    perl -MDevel::Kit -e 'ms($your_string_here)'

=head4 ss() SHA1

    perl -MDevel::Kit -e 'ss($your_string_here)'

=head3 Escape/Unescape Encode/Unencode

Unicode strings are turned into utf-8 before operating on it for consistency and since some, if not all, need to operate on bytes.

=head4 be() bu() Base64

    perl -MDevel::Kit -e 'be($your_string_here)'
    perl -MDevel::Kit -e 'bu($your_base64_here)'

=head4 ce() cu() Crockford (Base32)

    perl -MDevel::Kit -e 'ce($your_string_here)'
    perl -MDevel::Kit -e 'cu($your_crockford_here)'

=head4 xe() xu() Hex

    perl -MDevel::Kit -e 'xe($your_string_here)'
    perl -MDevel::Kit -e 'xu($your_hex_here)'

xe() takes a second boolean arg that when true dumps it as a visual mapping of each character to its hex value.

=head4 ue() uu() URI

    perl -MDevel::Kit -e 'ue($your_string_here)'
    perl -MDevel::Kit -e 'uu($your_uri_here)'

=head4 he() hu() HTML

    perl -MDevel::Kit -e 'he($your_string_here)'
    perl -MDevel::Kit -e 'hu($your_html_here)'

=head4 pe() pu() Punycode string

    perl -MDevel::Kit -e 'pe($your_string_here)'
    perl -MDevel::Kit -e 'pu($your_punycode_here)'

=head4 qe() qu() quoted-printable

    perl -MDevel::Kit -e 'qe($your_string_here)'
    perl -MDevel::Kit -e 'qu($your_quoted_printable_here)'

=head4 se() su() String escaped for perl

    perl -MDevel::Kit -e 'se($your_string_here)'
    perl -MDevel::Kit -e 'su($your_escaped_for_perl_string_here)'

=head2 non-imported functions

Feel free to override these with your own if you need different behavior.

=head3 Devel::Kit::o()

Outputs the first and only arg.

Goes to STDOUT and gaurantees it ends in one newline.

=head3 Devel::Kit::p()

Returns a stringified version of any type of perl ref() contained in the first and only arg.

=head1 DIAGNOSTICS

Errors are output in the various dumps.

=head1 CONFIGURATION AND ENVIRONMENT

Devel::Kit requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Import::Into> for the strict/warnings.

L<String::UnicodeUTF8> for string fiddling

L<Module::Want> to lazy load the various parsers and what not:

=over 4

=item L<Data::Dumper>

=item L<File::Slurp>

=item L<YAML::Syck>

=item L<JSON::Syck>

=item L<XML::Parser>

=item L<Storable>

=item L<Data::MessagePack>

=item L<Digest::MD5>

=item L<Digest::SHA>

=item L<MIME::QuotedPrint>

=item L<HTML::Entities>

=item L<URI::Escape>

=item L<MIME::Base64>

=item L<Devel::Symdump>

=item L<Time::HiRes>

=item L<Unix::PID::Tiny>

=item L<Devel::CountOps>

=item L<Devel::Size>

=item L<Devel::Peek>

=item L<Cwd>

=item L<Config>

=item L<Regexp::Debugger>

=back

=head1 SUBCLASSES

It includes 2 sub classes that can be used as guides on how to create your own context specific subclass:

L<Devel::Kit::TAP> for testing context (using a function based output).

L<Devel::Kit::cPanel> for cPanel context (using a method based output).

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-devel-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

=over 4

=item * auto-detect and switch to correct subclass

=item * *d() functions could use corresponding d*() functions (e.g. dy() would dump as YAML …)

=item * Stringified Data dumpers also take path or handle in addition to a string.

=item * string parser/dumpers make apparent what it was (i.e. YAML, XML, etc)

=back

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
