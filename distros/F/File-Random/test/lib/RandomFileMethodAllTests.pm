package RandomFileMethodAllTests;
use base qw/RandomFileSimpleDirOption
            RandomFileCheckOption
			RandomFileRecursiveOption
			RandomFilePassesPathsToCheckRoutine
            RandomFileWithUnknownParameters/;
            
use strict;
use warnings;

use Test::More;

use constant ALIASES =>({},
                        {-dir => '-d', -recursive => '-r', -check => '-c'},
                        {-dir => '-directory', '-recursive' => '-rec'});

my %current_aliases;

sub random_file {
    my ($self, %args) = @_;
    my %alias_args;
    while (my ($option, $value) = each %args) {
        $alias_args{ $current_aliases{$option} || $option } = $value;
    }                 
    return $self->SUPER::random_file(%alias_args);
}

sub content_of_random_file {
   my ($self, %args) = @_;
   my %alias_args;
   while (my ($option, $value) = each %args) {
       $alias_args{ $current_aliases{$option} || $option } = $value;
   }                 
   return $self->SUPER::content_of_random_file(%alias_args);
}

# Quite a dirty trick to overwrite runtests
# but I want to run all tests for every alias one time
#
# If you know something better, please email me
sub runtests {
    my $self = shift;
    foreach (ALIASES) {
        %current_aliases = %$_;
        diag("Test aliases: ", %current_aliases) if %current_aliases;
        $self->SUPER::runtests();
    }
}

1;
