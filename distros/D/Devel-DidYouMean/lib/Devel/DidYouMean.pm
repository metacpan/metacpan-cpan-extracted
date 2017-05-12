use 5.008;
use strict;
use warnings;
package Devel::DidYouMean;
$Devel::DidYouMean::VERSION = '0.05';
use Text::Levenshtein;
use Perl::Builtins;

# ABSTRACT: Intercepts failed function and method calls, suggesting the nearest matching alternative.


our $DYM_MATCHING_SUBS = [];

$SIG{__DIE__} = sub {

    no strict qw/refs/;
    my ($error, $package, $sub_name, $new_error) = @_;

    my $undef_sub = qr/^Undefined subroutine &(.+?) called (at .+?\.)/;
    my $missing_method = qr/^Can't locate object method "(.+?)" via package "(.+?)" (at .+?\.)/;

    if ($error =~ /$undef_sub/)
    {
        my @sub_path = split /::/, $1;
        $sub_name = pop @sub_path;
        $package = join '::', @sub_path;
        $new_error = $2;
    }
    elsif ($error =~ /$missing_method/)
    {
        $sub_name = $1;
        $package = $2;
        $new_error = $3;
    }
    else
    {
        print "No match\n";
        return undef;
    }

    my $package_namespace = $package . '::';
    my %valid_subs = ();

    for (keys %$package_namespace)
    {
        my $absolute_name = $package_namespace . $_;
        if (defined &{$absolute_name})
        {
            $valid_subs{$_} = Text::Levenshtein::fastdistance($sub_name, $_);
        }
    }

    # if package is main, add in builtin functions
    if ($package eq 'main')
    {
        for (Perl::Builtins::list)
        {
            $valid_subs{$_} = Text::Levenshtein::fastdistance($sub_name, $_);
        }
    }

    $DYM_MATCHING_SUBS = [];
    my $match_score;

    # return similarly named functions
    for (sort { $valid_subs{$a} <=> $valid_subs{$b} } keys %valid_subs)
    {
        $match_score = $valid_subs{$_} unless $match_score;

        if ($match_score < $valid_subs{$_})
        {
            die $error . "Did you mean " . join(', ', @$DYM_MATCHING_SUBS) . "?\n";
        }
        push @$DYM_MATCHING_SUBS, $_;
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::DidYouMean - Intercepts failed function and method calls, suggesting the nearest matching alternative.

=head1 VERSION

version 0.05

=head2 SYNOPSIS

    #!/usr/bin/env perl

    # somescript.pl
    use Data::Dumper;
    use Devel::DidYouMean;

    print Dumpr($data); # wrong function name

*Run the code*

    $ somescript.pl
    Undefined subroutine &main::Dumpr called at somescript.pl line 7.
    Did you mean Dumper?

Or as a one liner:

    $ perl -MData::Dumper -MDevel::DidYouMean -e 'print Dumpr($data)'
    Undefined subroutine &main::Dumpr called at -e line 1.
    Did you mean Dumper?

Or trap the error and extract the matching subs

    use Devel::DidYouMean;
    use Try::Tiny;

    try
    {
        sprintX("", $text); # boom
    }
    catch
    {
        my $error_msg = $_;
        my @closest_matching_subs = @$Devel::DidYouMean::DYM_MATCHING_SUBS;

        # do something cool here
    }

=head2 DESCRIPTION

L<Devel::DidYouMean> intercepts failed function and method calls, suggesting the nearest matching available subroutines in the context in which the erroneous function call was made.

=head2 THANKS

This module was inspired by Yuki Nishijima's Ruby gem L<did_you_mean|https://github.com/yuki24/did_you_mean>.

Chapter 9 "Dynamic Subroutines" in L<Mastering Perl|http://shop.oreilly.com/product/0636920012702.do> second edition by brian d foy was a vital reference for understanding Perl's symbol tables.

tipdbmp on L<reddit|http://www.reddit.com/r/perl/comments/2kw4g9/implementing_did_you_mean_in_perl/> for pointing me in the direction of signal handling instead of the previous AUTOLOAD approach.

=head2 SEE ALSO

L<Symbol::Approx::Sub> is a similar module that catches invalid subroutine names and then executes the nearest matching subroutine it can find. It does not export AUTOLOAD to all namespaces in the symbol table.

Mark Jason Dominus' 2014 !!Con L<talk|http://perl.plover.com/yak/HelpHelp/> and 2008 blog L<post|http://blog.plover.com/prog/perl/Help.pm.html> about a similar function.

=head1 AUTHOR

David Farrell <sillymoos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by David Farrell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
