package Devel::XRay;

use warnings;
use strict;
use Filter::Simple;
use Carp qw(croak);

our $VERSION = '0.95';

BEGIN {
    use constant DEBUG => 0;

    unless ( exists $INC{'Time/HiRes.pm'} ) {
        eval { require Time::HiRes; };
    }
    our $timing =
        exists $INC{'Time/HiRes.pm'}
        ? 'sprintf("%.6f", &Time::HiRes::time())'
        : 'sprintf("%d", time)';

    our %operations = (
        only   => \&_only,
        ignore => \&_ignore,
        all    => \&_all,
        none   => \&_none,
    );

    our $operation;
    our $subs  = '';
    our $trace = ' print STDERR "[" . ' . $timing
        . ' . "] " . (caller(0))[3] . "\\n";';
    our $all_regex = qr/(sub\s+\w.+?{)/s;
    our $regex     = '';

    sub import {
        ( undef, $operation, my (@subs) ) = @_;

        if ($operation) {
            croak "unknown import operation: $operation"
                unless exists $operations{$operation};
            croak "sub list required for operation: $operation\n"
                unless $operation eq 'all' || $operation eq 'none' || @subs;
            $regex = '(sub\s+(?:' . join( '|', @subs ) . ')\s*\{)';
            $regex = $regex . quotemeta($trace) if $operation eq 'ignore';

            #warn "regex: $regex\n";
            $regex = qr/$regex/s;
        }
        else {
            $operation = 'all';
        }
    }

    sub _only   { s/$regex/$1$trace/g; }
    sub _ignore { _all($_); s/$regex/$1/g; }
    sub _all    { s/$all_regex/$1$trace/g; }
    sub _none   { }

    FILTER {
        return unless $_;
        warn "performing operation: $operation\n" if DEBUG;
        $operations{$operation}->($_);
        warn $_ . "\n" if DEBUG;
    }
}

1;

__END__

=head1 NAME

Devel::XRay - See What a Perl Module Is Doing

=head1 VERSION

Version 0.95

=head1 SYNOPSIS

use Devel::XRay along with C<ignore>, C<only>, or C<all>,

    use Devel::XRay;
    use Devel::XRay 'all';    # same as saying 'use Devel::XRay;'
    use Devel::XRay 'none';   # filter the source but don't inject anything
    use Devel::XRay ignore => qw(man_behind_curtain private);
    use Devel::XRay only   => qw(sex drugs rock_and_roll);

=head1 DESCRIPTION

Devel::XRay is a handy source filter using L<Filter::Simple> when
used at the top of perl code, will inject print statements to 
standard error to show you what a module is doing.

This module is useful if...

=over 4

=item * 

You're a visual learner and want to "see"  program execution

=item *  

You're tracking an anomaly that leads you into unfamiliar code

=item *  

You want to quickly see how a module _runs_

=item *  

You've inherited code and need to grok it

=item *  

You start a new job and want to get a fast track on how things work

=back

=head1 EXAMPLES

    #!/usr/bin/perl
    use strict;
    use warnings;
    use Devel::XRay;

    use Example::Object;

    init();
    my $example = Example::Object->new();
    my $name = $example->name();
    my $result = $example->calc();
    cleanup();

    sub init    {}
    sub cleanup {}

    # In a another file, say Example/Object.pm
    package Example::Object;
    use Devel::XRay;
    sub new { bless {}, shift }
    sub name {}
    sub calc {}

Produces the following output

    # Hires seconds     # package::sub
    [1092265261.834574] main::init
    [1092265261.836732] Example::Object::new
    [1092265261.837563] Example::Object::name
    [1092265261.838245] Example::Object::calc
    [1092265261.839443] main::cleanup

=cut


=head1 ACKNOWLEDGEMENTS

This module was inspired by Damian Conway's Sufficently Advanced 
Technology presentation at YAPC::NA 2004.  I had initially attempted 
to use L<Hook::LexWrap>, but using L<Filter::Simple> was just a lot 
cleaner and seemed a bit more practical for debugging code.  The 
first iteration was only 2 lines of actual code.

    package Devel::XRay;
    use strict;
    use warnings;
    use Filter::Simple;

    my $code = 'print STDERR (caller(0))[3] . "\n";';
    FILTER { return unless $_; $_ =~ s/(sub.+?{)/$1 $code/sg; }

I'd also like to thank fellow SouthFlorida.pm member Rocco Caputo 
for working out the import logic over Sub Etha Edit at OSCON.  
Rock on Rocco!

=head1 AUTHOR

Jeff Bisbee, C<< <jbisbee at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-xray at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-XRay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::XRay

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-XRay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-XRay>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-XRay>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-XRay>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jeff Bisbee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<JavaScript::XRay>, L<Filter::Simple>, L<Time::HiRes>, L<Hook::LexWrap>, L<Devel::Trace>

