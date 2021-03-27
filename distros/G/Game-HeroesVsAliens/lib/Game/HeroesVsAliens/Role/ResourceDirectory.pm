package Game::HeroesVsAliens::Role::ResourceDirectory;

use Moo::Role;

has resource_directory => (
        is => 'rw',
        lazy => 1,
        default => sub {
                my $current =  __FILE__;
                $current =~ s/(.*HeroesVsAliens[\/\\])(.*)/$1/;
                return $current;
        }
);

1;
