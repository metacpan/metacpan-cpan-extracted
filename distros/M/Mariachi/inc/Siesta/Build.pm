use strict;
package Siesta::Build;
use Module::Build;
use File::Find qw(find);
use IO::File;
use base 'Module::Build';
use vars qw/$FAKE/;

sub create_build_script {
    my $self = shift;
    $self->SUPER::create_build_script;

    # check for incompatible steps
    my $module = $self->{properties}{module_name};
    if (my $version = $self->check_installed_version($module, 0)) {
        print "Upgrading from $module $version\n";
        my $fh = IO::File->new('Changes');
        my $chunk = '';
        my $this;
        while (<$fh>) {
            if (/^(\S+)/) {
                print "Incompatible change introduced in version $this:\n", $chunk
                    if $chunk =~ /INCOMPATIBLE/;
                $this = $1;
                last if $self->check_installed_version( $module, $this );
                $chunk = '';
            }
            $chunk .= $_;
        }
    }
}

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install;
    $self->ACTION_install_extras;
}

sub ACTION_fakeinstall {
    my $self = shift;
    $self->SUPER::ACTION_fakeinstall;
    local $FAKE = 1;
    $self->ACTION_install_extras;
}

sub ACTION_install_extras {
    my $self = shift;
    my $path = $self->{config}{__extras_destination};
    my @files = $self->_find_extras;
    print "installing extras to $path\n";
    for (@files) {
        $FAKE
          ? print "$_ -> $path/$_ (FAKE)\n"
          : $self->copy_if_modified($_, $path);
    }
}

sub ACTION_cover {
    my $self = shift;
    $self->depends_on('build');
    system qw( cover -delete );

    # sometimes we get failing tests, which makes Test::Harness
    # die.  catch that
    eval {
        local $ENV{PERL5OPT} = "-MDevel::Cover=-summary,0";
        $self->ACTION_test(@_);
    };
    system qw( cover -report html );
}

sub _find_extras {
    my $self = shift;
    my @files;
    find(sub {
             $File::Find::prune = 1 if -d && /^\.svn$/;
             return if -d;
             return if /~$/;
             push @files, $File::Find::name;
         }, @{ $self->{config}{__extras_from} });
    return @files;
}

1;
