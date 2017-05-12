package File::ShareDir::Override;

use strict;
use warnings;

# ABSTRACT: Override directories returned by File::ShareDir

our $VERSION = '0.200'; # VERSION

use File::ShareDir;

my %dist_dirs;
my %module_dirs;

sub import {
    my ($package, $dir) = @_;

    return if !defined $dir;
    
    if ($dir =~ /:/) {
        map {
            my @opt = split /(?<!:):(?!:)/, $_;

            if ($opt[0] =~ /::/) {
                # module_dir ("Foo::Bar:/some/path")
                $module_dirs{$opt[0]} = $opt[2] || $opt[1];
            }
            elsif (defined $opt[2]) {
                if ($opt[1] eq 'dist') {
                    # dist_dir ("Foo:dist:/some/path")
                    $dist_dirs{$opt[0]} = $opt[2];
                }
                elsif ($opt[1] eq 'module') {
                    # module_dir ("Foo:module:/some/path")
                    $module_dirs{$opt[0]} = $opt[2];
                }
            }
            else {
                # Assume dist_dir ("Foo-Bar:/some/path" or "Foo:/some/path")
                $dist_dirs{$opt[0]} = $opt[1];
            }
        } split ';', $dir;
    }
    else {
        # TODO: Guess the distribution and the share directory?
    }
}

{
    my $_File_ShareDir_dist_dir = \&File::ShareDir::dist_dir;
    my $_File_ShareDir_dist_file = \&File::ShareDir::dist_file;
    my $_File_ShareDir_module_dir = \&File::ShareDir::module_dir;
    my $_File_ShareDir_module_file = \&File::ShareDir::module_file;

    no strict 'refs';
    no warnings 'redefine';

    *{"File::ShareDir::dist_dir"} = sub {
        my $dist = File::ShareDir::_DIST(shift);

        return $dist_dirs{$dist} || &$_File_ShareDir_dist_dir($dist);
    };

    *{"File::ShareDir::dist_file"} = sub {
        my $dist = File::ShareDir::_DIST(shift);
        my $file = File::ShareDir::_FILE(shift);

        if ($dist_dirs{$dist}) {
            return File::Spec->catfile($dist_dirs{$dist}, $file);
        }
        else {
            return &$_File_ShareDir_dist_file($dist, $file);
        }
    };

    *{"File::ShareDir::module_dir"} = sub {
        my $module = File::ShareDir::_MODULE(shift);

        return $module_dirs{$module} || &$_File_ShareDir_module_dir($module);
    };
    
    *{"File::ShareDir::module_file"} = sub {
        my $module = File::ShareDir::_MODULE(shift);
        my $file = File::ShareDir::_FILE(shift);

        if ($module_dirs{$module}) {
            return File::Spec->catfile($module_dirs{$module}, $file);
        }
        else {
            return &$_File_ShareDir_module_file($module, $file);
        }
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ShareDir::Override - Override directories returned by File::ShareDir

=head1 VERSION

version 0.200

=head1 SYNOPSIS

Run C<program.pl> and make Foo::Bar think its distribution's shared directory is
C<./share>:

    perl -MFile::ShareDir::Override=Foo-Bar:./share program.pl

Pretend Foo::Bar's module shared directory is C<./lib>:

    perl -MFile::ShareDir::Override=Foo::Bar:./lib program.pl

=head1 DESCRIPTION

(TBA)

Top-level modules/distributions (e.g., Dancer or Plack) don't have any dashes or
double colons in the name and can't be recognized, so they need an explicit
C<:dist> or C<:module> between the name and path. Example:

    perl -MFile::ShareDir::Override=Foo:module:./lib program.pl

Usage with C<prove>:

    PERL5OPT=-MFoo-Bar:./share prove sometests.t

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/odyniec/p5-File-ShareDir-Override/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/odyniec/p5-File-ShareDir-Override>

  git clone https://github.com/odyniec/p5-File-ShareDir-Override.git

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
