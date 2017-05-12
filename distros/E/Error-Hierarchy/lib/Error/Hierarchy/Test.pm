use 5.008;
use strict;
use warnings;

package Error::Hierarchy::Test;
BEGIN {
  $Error::Hierarchy::Test::VERSION = '1.103530';
}
# ABSTRACT: Tools to test hierarchical exceptions
use Test::Builder;
use Test::Exception;
use Error ':try';
use Exporter qw(import);
our %EXPORT_TAGS = (misc => [qw{throws2_ok exception_ok}],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };
my $Tester = Test::Builder->new;
*_exception_as_string = *Test::Exception::_exception_as_string;

sub exception_ok ($$$;$) {
    my ($E, $class, $content, $test_name) = @_;
    local $Error::Depth = $Error::Depth + 1;
    if (ref($E) && $E->isa('Error::Hierarchy::Container')) {
        $E = $E->shift_items;
    }
    my $ok = ref $E eq $class;
    $ok &&=
      ref $content eq 'Regexp'
      ? $E =~ m/$content/
      : $E eq $content;
    $test_name ||= _exception_as_string(threw => $class);
    $Tester->ok($ok, $test_name);
    unless ($ok) {
        $Tester->diag(_exception_as_string('expecting:', "$class ($content)"));
        $Tester->diag(_exception_as_string('found:',     $E));
    }
    $ok;
}

sub throws2_ok (&$$;$) {
    my ($sub, $class, $content, $test_name) = @_;
    local $Error::Depth = $Error::Depth + 1;
    my ($E, $ok);
    try {
        &$sub;
    }
    catch Error with {
        $E = shift;
        exception_ok($E, $class, $content, $test_name);
    }
    finally {
        unless (defined $E) {
            $Tester->ok(0, $test_name);
            $Tester->diag('did not throw an exception');
        }
    };
    $ok;
}
1;


__END__
=pod

=head1 NAME

Error::Hierarchy::Test - Tools to test hierarchical exceptions

=head1 VERSION

version 1.103530

=head1 SYNOPSIS

  throws2_ok {
      # ...
  }, 'Some::Exception',
     qr/text that \s* appears in the exception message/,
     "this test's name";

=head1 DESCRIPTION

This module provides some tools that help in testing hierarchical exceptions.

=head1 FUNCTIONS

=head2 exception_ok

Takes as arguments in the given order: an exception object, a class name, the
expected content and optionally a test name.

First we check whether the exception object is of the given class type. If it
is, we also check whether the stringified exception matches the expected
content. If the content is a string, the content has to be equal to the
stringified exception. If the content is a regex, the content has to match the
stringified exception.

The first argument can also be a L<Error::Hierarchy::Container>, in which case
the first exception stored in the container will be tested.

If the test name is not given, the stringified exception is used.

Otherwise it behaves like L<Test::More>'s C<ok()>. If the test was not ok, a
diagnostic is printed.

=head2 throws2_ok

Takes as arguments in the given order: A code reference, a class name, the
expected content and optionally a test name.

The code reference is executed in a C<try>/C<catch> block. The test is ok if
the code threw the given exception, with semantics per C<exception_ok()>.

Diagnostics are printed if the exception did not match the expectations, or if
no exception was thrown.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Error-Hierarchy>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Error-Hierarchy/>.

The development version lives at L<http://github.com/hanekomu/Error-Hierarchy>
and may be cloned from L<git://github.com/hanekomu/Error-Hierarchy>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

