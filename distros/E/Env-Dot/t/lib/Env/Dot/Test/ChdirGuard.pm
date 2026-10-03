package Env::Dot::Test::ChdirGuard;
use strict;
use warnings;
use 5.010;

# ABSTRACT: Scope-based chdir guard.

use Carp qw( croak );
use English '-no_match_vars';

our $VERSION = '0.022';


=pod

=head1 STATUS

This module is currently being developed so changes in the API are possible,
though not likely.


=head1 SYNOPSIS

=for test_synopsis BEGIN { die 'SKIP: no .env file here' }

    my $guard = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $some_tempdir or die ...;
    # ... work happens here ...
    # $guard goes out of scope -> cwd is restored automatically.

=head1 DESCRIPTION

Scope-based chdir guard. Construct with the directory to return to
(typically the current working directory captured *before* chdir-ing
elsewhere); when the guard object goes out of scope its DESTROY chdirs
back. This keeps each subtest isolated even if it dies mid-way, so
later subtests always start from a known cwd.

=cut

sub new { my ($class, $dir) = @_; return bless { dir => $dir }, $class; }

sub DESTROY { my ($self) = @_; chdir $self->{'dir'} or croak "Cannot chdir: $OS_ERROR"; return; }

1;
