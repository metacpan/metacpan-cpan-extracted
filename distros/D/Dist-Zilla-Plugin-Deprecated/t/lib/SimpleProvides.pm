package SimpleProvides;

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

sub metadata
{
    my $self = shift;

    my $version = $self->zilla->version;
    return +{
        provides => {
            map {
                # this is an awful hack and assumes ascii package names:
                # please do not cargo-cult this code elsewhere. The proper
                # thing to do is to crack open the file and read the package
                # name(s) (e.g. with Module::Metadata)
                my $filename = $_->name;
                (my $package = $filename) =~ s{[/\\]}{::}g;
                $package =~ s/^lib:://;
                $package =~ s/\.pm$//;
                $package => +{ file => $filename, version => $version }
            } grep { $_->name =~ /^lib\/.*\.pm$/} @{ $self->zilla->files }
        }
    };
}

1;
