package Getopt::Complete::Compgen;

use strict;
use warnings;

our $VERSION = $Getopt::Complete::VERSION;

# Support the shell-builtin completions.
# Some hackery seems to be required to replicate regular file completion.
# Case 1: you want to selectively not put a space after some options (incomplete directories)
# Case 2: you want to show only part of the completion value (the last dir in a long path)

# Manufacture the long and short sub-names on the fly.
for my $subname (qw/
    files
    directories
    commands
    users
    groups
    environment
    services
    aliases
    builtins
/) {
    my $option = substr($subname,0,1);
    my $code = sub {
        my ($command,$value,$key,$args) = @_;
        $value ||= '';
        $value =~ s/\\/\\\\/;
        $value =~ s/\'/\\'/;
        my @f =  grep { $_ !~/^\s+$/ } `bash -c "compgen -$option -- '$value'"`; 
        chomp @f;
        if ($option eq 'f' or $option eq 'd') {
            # bash is fine with ~/ paths but perl is not, need to translate
            my $home_dir = (getpwuid($<))[7];
            for (my $i = 0; $i < @f; $i++) {
                my $perl_path = $f[$i];
                $perl_path =~ s/^~/$home_dir/;
                if ( -d $perl_path ) {
                    $f[$i] .= "/\t";
                }
            }

            my @not_shown = ($value);
            push @f, \@not_shown;
            push @not_shown, '-' if $Getopt::Complete::LONE_DASH_SUPPORT and $option eq 'f';
        }
        return \@f;
    };
    no strict 'refs';
    *$subname = $code;
    *$option = $code;
    *{ 'Getopt::Complete::' . $subname } = $code;
    *{ 'Getopt::Complete::' . $option } = $code;
}

1;

=pod 

=head1 NAME

Getopt::Complete::Compgen - standard tab-completion callbacks

=head1 VERSION

This document describes Getopt::Complete::Compgen 0.26.

=head1 SYNOPSIS

 # A completion spec can use any of the following, specified by a single
 # word, or a single character, automatically:
 
 use Getopt::Complete(
    'myfile'    => 'files',         # or 'f'
    'mydir'     => 'directories',   # or 'd'
    'mycommand' => 'commands',      # or 'c'
    'myuser'    => 'users',         # or 'u'
    'mygroup'   => 'groups',        # or 'd'
    'myenv'     => 'environment',   # or 'e'
    'myservice' => 'services',      # or 's'
    'myalias'   => 'aliases',       # or 'a'
    'mybuiltin' => 'builtins'       # or 'b'
 );

 

=head1  DESCRIPTION

This module contains subroutines which can be used as callbacks with Getopt::Complete,
and which implement all of the standard completions supported by the bash "compgen" builtin.

Running "compgen -o files abc" will produce the completion list as though the user typed "abc<TAB>",
with the presumption the user is attempting to complete file names.

This module provides a subroutine names "files", with an alias named "f", which returns the same list.

The subroutine is suitable for use in a callback in a Getopt::Complete competion specification.

It does the equivalent for directories, executable commands, users, groups, environment variables, services,
aliases and shell builtins.

These are the same:

 @matches = Getopt::Complete::Compgen::files("whatevercommand","abc","whateverparam",$whatever_other_args);
 
 @same = `bash -c "compgen -f sometext"`;
 chomp @same;

These are equivalent in any spec:

   \&Getopt::Complete::Compgen::files
   \&Getopt;:Complete::Compgen::f
  'Getopt::Complete::Compgen::files'
  'Getopt;:Complete::Compgen::f'
  'files'
  'f'

=head1 SEE ALSO

L<Getopt::Complete>

The manual page for bash details the bash built-in command "compgen", which this wraps.

=head1 COPYRIGHT

Copyright 2010 Scott Smith and Washington University School of Medicine

=head1 AUTHORS

Scott Smith (sakoht at cpan .org)

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this
module.

=cut

