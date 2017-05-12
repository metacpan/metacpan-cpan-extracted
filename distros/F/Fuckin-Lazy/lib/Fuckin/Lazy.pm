package Fuckin::Lazy;
use strict;
use warnings;

use Data::Dumper;
use base 'Exporter';
use Carp qw/croak/;

our $VERSION = "0.000002";
our @EXPORT = ('LAZY');

sub produce_data {
    my ($struct, $line, $match) = @_;
    local $Data::Dumper::Purity   = 1;
    local $Data::Dumper::Useqq    = 1;
    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent   = 0;

    my $data = Dumper($struct);

    $data =~ s/\$VAR1 = //;
    $data =~ s/;$//;
    chomp($data);

    return $data;
}

sub LAZY {
    my ($struct) = @_;

    my ($caller, $file, $line) = caller();

    open(my $fh, '<', $file) || die "Could not open $file: $!";

    my $updated = 0;
    my @lines;
    while (my $line = <$fh>) {
        if ($line =~ m/(LAZY|Fuckin'Lazy|Fuckin::Lazy)\s*\(/) {
            my $match = $1;
            croak "$1() must be called with parentheses, and must be given a scalar variable for an arg."
                unless $line =~ m/$match\(\s*\$[0-9A-Za-z_]+\s*\)/;

            my $data = produce_data($struct, $line, $match);
            $line =~ s/$match\(\s*\$[0-9A-Za-z_]+\s*\)/$data/;
        }
        push @lines => $line;
    }

    close($fh);
    open($fh, '>', $file) || die "Cannot open $file for writing: $!";

    print $fh @lines;

    return $struct;
}

*Fuckin::Lazy = \&LAZY;

1;

__END__

=head1 NAME

Fuckin::Lazy - Lazy way to produce test structures (Or a very bad idea)

=head1 WARNING

Warning! Using the module would fall squarely into B<BAD PRACTICE>. You should
predict what structures your code produces and put them into the test yourself.
Simply dumping a result and testing against it is a bad idea. The only
exception to this policy is when writing tests to make sure the output does not
change from what it currently is.

=head1 SYNOPSIS

    use Test::More;
    use Fuckin::Lazy qw/LAZY/;

    my $foo = { a => 1, b => 2 };

    is_deeply($foo, Fuckin'Lazy($foo), "Foo");

    is_deeply(
        $foo,
        LAZY($foo),
        "Foo"
    );

    is_deeply($foo, LAZY($foo), "Foo");

    done_testing;

The first time you run the above test it will alter the test file itself to produce this:

    use Test::More;
    use Fuckin::Lazy qw/LAZY/;

    my $foo = { a => 1, b => 2 };

    is_deeply($foo, {"a" => 1,"b" => 2}, "Foo");

    is_deeply(
        $foo,
        {"a" => 1,"b" => 2},
        "Foo"
    );

    is_deeply($foo, {"a" => 1,"b" => 2}, "Foo");

    done_testing;

=head1 DESCRIPTION

A poor implementation of a bad idea!

=head1 EXPORTS

=over 4

=item LAZY($var)

This function will turn the argument into the code for a perl data structure
and replace itself with the code. This is done when the file is run. The data
structure passed in is returned unchanged allowing the test to pass.

=back

=head1 MAGIC

=over 4

=item Fuckin'Lazy($var)

Same as the LAZY() export, except it is the Fuckin::Lazy function, not
exported. The C<'> can be used in place of C<::> due to legacy perl support.

=back

=head1 IDEA

Thanks to Joshua Keroes for proposing the idea.

C<"Fucking::Lazy is beautifully horrible"> - mst

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

