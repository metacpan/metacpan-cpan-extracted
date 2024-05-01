package Lemonldap::NG::Common::Conf::Backends::Overlay;

use Lemonldap::NG::Common::Conf::Constants qw($hashParameters );
use JSON;

our $VERSION = '2.19.0';

sub load {
    my ( $self, $cfgNum, $fields ) = @_;
    my @files = eval { overList($self) };
    if ($@) {
        $Lemonldap::NG::Common::Conf::msg .= $@;
        return undef;
    }
    my $conf =
      &{"Lemonldap::NG::Common::Conf::Backends::$self->{overlayRealtype}::load"}
      (@_);
    my @errors;
    foreach my $file (@files) {
        if ( open my $f, '<', "$self->{overlayDirectory}/$file" ) {
            local $/ = undef;
            my $content = <$f>;
            close $f;
            if ( $file =~ $hashParameters ) {
                eval { $content = JSON::from_json($content) };
                if ($@) {
                    push @errors, "Bad over file $file: $@";
                }
                else {
                    $conf->{$file} = $content;
                }
            }
            else {
                $content =~ s/^\s*(.*?)\s*$/$1/;
                $conf->{$file} = $content;
            }
        }
        else {
            push @errors, $!;
        }
    }
    if (@errors) {
        $Lemonldap::NG::Common::Conf::msg .= join "\n", @errors;
        return undef;
    }
    return $conf;
}

sub store {
    my ( $self, $fields ) = @_;
    my @files = eval { overList($self) };

    my @errors;
    foreach my $file (@files) {
        my $data = delete $fields->{$file};
        if ( $self->{overlayWrite} ) {
            if ( open my $f, '>', "$self->{overlayDirectory}/$file" ) {
                print $f (
                    $file =~ $hashParameters ? JSON::to_json($data) : $data );
                close $f;
            }

            else {
                push @errors, "Unable to write over file $file: $@";
            }
        }
    }

    die join( "\n", @errors ) if $@;

    return &{
        "Lemonldap::NG::Common::Conf::Backends::$self->{overlayRealtype}::store"
    }( $self, $fields );
}

sub overList {
    my ($self) = @_;

    my $overDir = $self->{overlayDirectory} or die 'Missing overlayDirectory';
    die "$overDir directory doesn't exist" unless -d $overDir and -r $overDir;
    opendir my $dir, $overDir or die $!;
    my @files = grep /^[^\.]/, readdir $dir;
    closedir $dir;
    my @errors;

    foreach my $file (@files) {
        if ( open my $f, '<', "$overDir/$file" ) {
            local $/ = undef;
            my $content = <$f>;
            close $f;
            if ( $file =~ $hashParameters ) {
                eval { $content = JSON::from_json($content) };
                if ($@) {
                    push @errors, "Bad over file $file: $@";
                }
                else {
                    $conf->{$file} = $content;
                }
            }
            else {
                $content =~ s/^\s*(.*?)\s*$/$1/;
                $conf->{$file} = $content;
            }
        }
    }
    die join "\n", @errors if @errors;
    return @files;
}

sub AUTOLOAD {
    my ($self) = @_;
    die 'Missing overlayRealtype'
      unless $self->{overlayRealtype};
    eval
      "require Lemonldap::NG::Common::Conf::Backends::$self->{overlayRealtype}";
    die $@ if $@;
    $AUTOLOAD =~ s/::Overlay::/::$self->{overlayRealtype}::/;
    my @res = &{$AUTOLOAD}(@_);
    return wantarray ? (@res) : $res;
}

1;
