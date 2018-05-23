package Math::GrahamFunction::SqFacts;
$Math::GrahamFunction::SqFacts::VERSION = '0.02002';
use strict;
use warnings;


use parent qw(Math::GrahamFunction::Object);

use List::Util ();
__PACKAGE__->mk_accessors(qw(n factors));

sub _initialize
{
    my $self = shift;
    my $args = shift;

    if ($args->{n})
    {
        $self->n($args->{n});

        $self->_calc_sq_factors();
    }
    elsif ($args->{factors})
    {
        $self->factors($args->{factors});
    }
    else
    {
        die "factors or n must be supplied.";
    }

    return 0;
}


sub clone
{
    my $self = shift;
    return __PACKAGE__->new({'factors' => [@{$self->factors()}]});
}

sub _calc_sq_factors
{
    my $self = shift;

    $self->factors($self->_get_sq_facts($self->n()));

    return 0;
}

my %gsf_cache = (1 => []);

sub _get_sq_facts
{
    my $self = shift;
    my $n = shift;

    if (exists($gsf_cache{$n}))
    {
        return $gsf_cache{$n};
    }

    my $start_from = shift || 2;

    for(my $p=$start_from; ;$p++)
    {
        if ($n % $p == 0)
        {
            # This function is recursive to make better use of the Memoization
            # feature.
            my $division_factors = $self->_get_sq_facts(($n / $p), $p);
            if (@$division_factors && ($division_factors->[0] == $p))
            {
                return ($gsf_cache{$n} = [ @{$division_factors}[1 .. $#$division_factors] ]);
            }
            else
            {
                return ($gsf_cache{$n} = [ $p, @$division_factors ]);
            }
        }
    }
}

# Removed because it is too slow - we now use our own custom memoization (
# or perhaps it is just called caching)
# memoize('get_squaring_factors', 'NORMALIZER' => sub { return $_[0]; });

# This function multiplies the squaring factors of $n and $m to receive
# the squaring factors of ($n*$m)

# OOP-Wise, it should be a multi-method, but since we don't inherit this
# object it's all-right.


sub mult_by
{
    my $n_ref = shift;
    my $m_ref = shift;

    my @n = @{$n_ref->factors()};
    my @m =
    eval {
        @{$m_ref->factors()};
    };
    if ($@)
    {
        print "Hello\n";
    }

    my @ret = ();

    while (scalar(@n) && scalar(@m))
    {
        if ($n[0] == $m[0])
        {
            shift(@n);
            shift(@m);
        }
        elsif ($n[0] < $m[0])
        {
            push @ret, shift(@n);
        }
        else
        {
            push @ret, shift(@m);
        }
    }
    push @ret, @n, @m;

    $n_ref->factors(\@ret);

    # 0 for success
    return 0;
}


sub mult
{
    my $n = shift;
    my $m = shift;

    my $result = $n->clone();
    $result->mult_by($m);
    return $result;
}


sub is_square
{
    my $self = shift;
    return (scalar(@{$self->factors()}) == 0);
}


sub exists
{
    my ($self, $factor) = @_;

    return defined(List::Util::first { $_ == $factor } @{$self->factors()});
}


sub last
{
    my $self = shift;

    return $self->factors()->[-1];
}

use vars qw($a $b);


sub product
{
    my $self = shift;

    return (List::Util::reduce { $a * $b } @{$self->factors()});
}


sub first
{
    my $self = shift;

    return $self->factors()->[0];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::GrahamFunction::SqFacts - a squaring factors vector.

=head1 VERSION

version 0.02002

=head1 VERSION

version 0.02002

=head1 WARNING!

This is a module for Math::GrahamFunction's internal use only.

=head1 CONSTRUCTION

=head2 Math::GrahamFunction::SqFacts->new({n => $n})

Initializes a squaring factors object from a number.

=head2 Math::GrahamFunction::SqFacts->new({factors => \@factors})

Initializes a squaring factors object from a list of factors.

=head1 METHODS

=head2 $facts->clone()

Creates a clone of the object and returns it.

=head2 $n_facts->mult_by($m_facts)

Calculates the results of the multiplication of the number represented by
C<$n_facts> and C<$m_facts> and stores it in $n_facts (destructively).

This is actually addition in vector space.

=head2 my $result = $n->mult($m);

Non destructively calculates the multiplication and returns it.

=head2 $facts->is_square()

A predicate that returns whether the factors represent a square number.

=head2 $facts->exists($myfactor)

Checks whether C<$myfactor> exists in C<$facts>.

=head2 my $last_factor = $factors->last()

Returns the last (and greatest factor).

=head2 $facts->product()

Returns the product of the factors.

=head2 $facts->first()

Returns the first (and smallest) factor.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

B<Note:> the module meta-data says this module is released under the BSD
license. However, MIT X11 is the more accurate license, and "bsd" is
the closest option for the CPAN meta-data.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/math-grahamfunction/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Math::GrahamFunction::SqFacts

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Math-GrahamFunction>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Math-GrahamFunction>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-GrahamFunction>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Math-GrahamFunction>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Math-GrahamFunction>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Math-GrahamFunction>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/M/Math-GrahamFunction>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Math-GrahamFunction>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Math::GrahamFunction>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-math-grahamfunction at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Math-GrahamFunction>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/math-grahamfunction>

  git clone https://bitbucket.org/shlomif/perl-math-grahamfunction/

=cut
