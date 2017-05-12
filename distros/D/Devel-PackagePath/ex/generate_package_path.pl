#!/usr/bin/env perl -l
package App::GeneratePackagePath;
use Moose;

extends qw(Devel::GeneratePackagePath);
with qw(MooseX::Getopt);

sub run {
    print $_[0]->create;
}
__PACKAGE__->new_with_options->run;
