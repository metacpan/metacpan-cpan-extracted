package Exceptions;

our $VERSION = '0.103';

use strict;
use warnings;

1;

__END__

=head1 NAME

Exceptions - Documentation for exception handling in Perl.

=head1 DESCRIPTION

This module doesn't do anything, it exists solely to document how to handle
exceptions in Perl. It was originally released in 1996, but it hasn't been
installable or usable in any fashion since then.

Many other alternatives have cropped up over the years to make exception
handling much easier.

=head1 TRY CATCH FINALLY

If you want to skip the explanations below, then you should look directly at
some of the modules that make exception handling dead simple.

L<Syntax::Keyword::Try> - Catch exceptions in a familiar C<try> and C<catch>
way. If you look no further, make use of this module! This
module requires Perl v5.14 or better as it uses pluggable keywords.

If you can't make use of L<Syntax::Keyword::Try> because you're not on at least
version 5.14 of Perl, then you can use a pure-Perl module instead:

L<Try::Tiny> - Catch exceptions in a familiar C<try> and C<catch> way.

=head1 THROW

With a good way to catch exceptions, now you need exception types so you can
re-throw exceptions when they're something that should be handled elsewhere.

=over

=item *

L<Throwable> and L<Throwable::SugarFactory>

=item *

L<Exception::Class>

=item *

L<Mojo::Exception>

=back


=head1 AN EXCEPTION

Now that we've shown you what you should be using above, let's explain a bit of
the I<why> of it all.

An exception is what happens anytime your program's execution exits
unexpectedly. Let's start with a simple example.

    #!/usr/bin/env perl
    use strict;
    use warnings;

    print "0 plus 1 = ", increment(0), "\n"; # 1
    print "zero plus 1 = ", increment('zero'), "\n"; # Exception
    print "0 plus 1 = ", increment(0), "\n"; # never executes

    sub increment {
        my $int = shift;
        die "That's not an int!" unless defined $int && $int =~ /^[0-9]+\z/;
        return $int+1;
    }

This will result in the following output:

    $ perl increment.pl
    0 plus 1 = 1
    That's not an int! at foo.pl line 11.

The first line prints C<0 plus 1 = 1\n> as expected. The second line, however,
dies in a way that we can't recover from which prevents the rest of our program
from doing any further execution. So, we must handle our exceptions!

=head1 A HANDLED EXCEPTION

The only way you can handle an exception is to wrap the code that could
die in an C<eval> block. This sounds simple enough, but there are some gotchas
that lead many developers to do this incorrectly.

The correct way to handle an exception requires that you understand how to
preserve the global C<$@> variable and that its value cannot be relied upon to
determine whether an exception occurred. Please see L<Try::Tiny/BACKGROUND> for a
great explanation of this problem.

Let's look at our previous simple application with error handling using C<eval>.

    #!/usr/bin/env perl
    use strict;
    use warnings;

    # 1
    my $value;
    my $error;
    { # catch block
        local $@;
        $error = $@ || 'Error' unless eval { $value = increment(0); 1 }; # try
    }
    print "0 plus 1 = ", (defined $error ? "error": $value), "\n";

    # error
    $value = undef;
    $error = undef;
    { # catch block
        local $@;
        $error = $@ || 'Error' unless eval { $value = increment('zero'); 1 }; # try
    }
    print "zero plus 1 = ", (defined $error ? "error": $value), "\n";

    # 1
    $value = undef;
    $error = undef;
    { # catch block
        local $@;
        $error = $@ || 'Error' unless eval { $value = increment(0); 1 }; # try
    }
    print "0 plus 1 = ", (defined $error ? "error": $value), "\n";

    sub increment {
        my $int = shift;
        die "That's not an int!" unless defined $int && $int =~ /^[0-9]+\z/;
        return $int+1;
    }

As you can see, it gets quite ugly and cumbersome to handle exceptions this way.
Don't let that scare you away from Perl, though. Keep reading and be happy!

=head1 THE SOLUTION

Lucky for us, Perl is an awesome language where the community provides many
solutions to common tasks for us. One such solution is L<Syntax::Keyword::Try>.

If you get nothing else out of this document, let it be that using
L<Syntax::Keyword::Try> will save you time and heartache.

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Syntax::Keyword::Try;
    # since 5.14 is required, let's use those features
    use feature ':5.14';

    # 1
    try { say "0 plus 1 = ", increment(0); }
    catch { say "0 plus 1 = error"; }

    # error
    try { say "zero plus 1 = ", increment('zero'); }
    catch { say "zero plus 1 = error"; }

    # 1
    try { say "0 plus 1 = ", increment(0); }
    catch { say "0 plus 1 = error"; }

    sub increment {
        my $int = shift;
        die "That's not an int!" unless defined $int && $int =~ /^[0-9]+\z/;
        return $int+1;
    }


If you can't use L<Syntax::Keyword::Try>, you can use the pure-Perl L<Try::Tiny>
instead:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Try::Tiny qw(try catch);

    # 1
    try { print "0 plus 1 = ", increment(0), "\n"; }
    catch { print "0 plus 1 = error\n"; };

    # error
    try { print "zero plus 1 = ", increment('zero'), "\n"; }
    catch { print "zero plus 1 = error\n"; };

    # 1
    try { print "0 plus 1 = ", increment(0), "\n"; }
    catch { print "0 plus 1 = error\n"; };

    sub increment {
        my $int = shift;
        die "That's not an int!" unless defined $int && $int =~ /^[0-9]+\z/;
        return $int+1;
    }


=head1 AUTHOR

Chase Whitener <F<capoeirab@cpan.org>>

=head1 LICENSE AND COPYRIGHT

Copyright 1996 by Peter Seibel <F<pseibel@cpan.org>>. This original release
was made without an attached license.

Copyright 2016 by Chase Whitener <F<capoeirab@cpan.org>>. This re-release contains
none of the original code or structure and is thus re-released under the same
license as Perl itself.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
