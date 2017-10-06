
package Importer::Zim::EndOfScope;
$Importer::Zim::EndOfScope::VERSION = '0.2.0';
# ABSTRACT: Import functions with compilation block scope

use 5.010001;

BEGIN {
    require Importer::Zim::Base;
    Importer::Zim::Base->VERSION('0.8.0');
    our @ISA = qw(Importer::Zim::Base);
}

use B::Hooks::EndOfScope ();
use Sub::Replace         ();

use Importer::Zim::Utils 0.8.0 qw(DEBUG carp);

sub import {
    my $class = shift;

    carp "$class->import(@_)" if DEBUG;
    my @exports = $class->_prepare_args(@_);

    my $caller = caller;
    my $old    = Sub::Replace::sub_replace(
        map { ; "${caller}::$_->{export}" => $_->{code} } @exports );

    # Clean it up after a scope finished compilation
    B::Hooks::EndOfScope::on_scope_end(
        sub {
            warn qq{  Restoring @{[map qq{"$_"}, sort keys %$old]}\n}
              if DEBUG;
            Sub::Replace::sub_replace($old);
        }
    ) if %$old;
}

no Importer::Zim::Utils qw(DEBUG carp);

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Importer::Zim::EndOfScope 'Scalar::Util' => 'blessed';
#pod     use Importer::Zim::EndOfScope 'Scalar::Util' =>
#pod       ( 'blessed' => { -as => 'typeof' } );
#pod
#pod     use Importer::Zim::EndOfScope 'Mango::BSON' => ':bson'; 
#pod
#pod     use Importer::Zim::EndOfScope 'Foo' => { -version => '3.0' } => 'foo';
#pod
#pod     use Importer::Zim::EndOfScope 'SpaceTime::Machine' => [qw(robot rubber_pig)];
#pod
#pod =head1 DESCRIPTION
#pod
#pod     "Wait a minute! What planet is this?"
#pod       – Zim
#pod
#pod This is a backend for L<Importer::Zim> which makes
#pod imported symbols available during the compilation of
#pod the surrounding scope.
#pod
#pod Unlike L<Importer::Zim::Lexical>, it works for perls before 5.18.
#pod Unlike L<Importer::Zim::Lexical> which plays with lexical subs,
#pod this meddles with the symbol tables for a (hopefully short)
#pod time interval. (This time interval should be even shorter
#pod than the one that applies to L<Importer::Zim::Unit>.)
#pod
#pod =head1 HOW IT WORKS
#pod
#pod The statement
#pod
#pod     use Importer::Zim::EndOfScope 'Foo' => 'foo';
#pod
#pod works sort of
#pod
#pod     use B::Hooks::EndOfScope;
#pod
#pod     my $_OLD_SUBS;
#pod     BEGIN {
#pod         require Foo;
#pod         $_OLD_SUBS = Sub::Replace::sub_replace('foo' => \&Foo::foo);
#pod     }
#pod
#pod     on_scope_end {
#pod         Sub::Replace::sub_replace($_OLD_SUBS);
#pod     }
#pod
#pod That means:
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod Imported subroutines are installed into the caller namespace at compile time.
#pod
#pod =item *
#pod
#pod Imported subroutines are cleaned up after perl finished compiling
#pod the surrounding scope.
#pod
#pod =back
#pod
#pod See L<Sub::Replace> for a few gotchas about why this is not simply done
#pod with Perl statements such as
#pod
#pod     *foo = \&Foo::foo;
#pod
#pod =head1 DEBUGGING
#pod
#pod You can set the C<IMPORTER_ZIM_DEBUG> environment variable
#pod for get some diagnostics information printed to C<STDERR>.
#pod
#pod     IMPORTER_ZIM_DEBUG=1
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Importer::Zim>
#pod
#pod L<B::Hooks::EndOfScope>
#pod
#pod L<Importer::Zim::Lexical>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Importer::Zim::EndOfScope - Import functions with compilation block scope

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    use Importer::Zim::EndOfScope 'Scalar::Util' => 'blessed';
    use Importer::Zim::EndOfScope 'Scalar::Util' =>
      ( 'blessed' => { -as => 'typeof' } );

    use Importer::Zim::EndOfScope 'Mango::BSON' => ':bson'; 

    use Importer::Zim::EndOfScope 'Foo' => { -version => '3.0' } => 'foo';

    use Importer::Zim::EndOfScope 'SpaceTime::Machine' => [qw(robot rubber_pig)];

=head1 DESCRIPTION

    "Wait a minute! What planet is this?"
      – Zim

This is a backend for L<Importer::Zim> which makes
imported symbols available during the compilation of
the surrounding scope.

Unlike L<Importer::Zim::Lexical>, it works for perls before 5.18.
Unlike L<Importer::Zim::Lexical> which plays with lexical subs,
this meddles with the symbol tables for a (hopefully short)
time interval. (This time interval should be even shorter
than the one that applies to L<Importer::Zim::Unit>.)

=head1 HOW IT WORKS

The statement

    use Importer::Zim::EndOfScope 'Foo' => 'foo';

works sort of

    use B::Hooks::EndOfScope;

    my $_OLD_SUBS;
    BEGIN {
        require Foo;
        $_OLD_SUBS = Sub::Replace::sub_replace('foo' => \&Foo::foo);
    }

    on_scope_end {
        Sub::Replace::sub_replace($_OLD_SUBS);
    }

That means:

=over 4

=item *

Imported subroutines are installed into the caller namespace at compile time.

=item *

Imported subroutines are cleaned up after perl finished compiling
the surrounding scope.

=back

See L<Sub::Replace> for a few gotchas about why this is not simply done
with Perl statements such as

    *foo = \&Foo::foo;

=head1 DEBUGGING

You can set the C<IMPORTER_ZIM_DEBUG> environment variable
for get some diagnostics information printed to C<STDERR>.

    IMPORTER_ZIM_DEBUG=1

=head1 SEE ALSO

L<Importer::Zim>

L<B::Hooks::EndOfScope>

L<Importer::Zim::Lexical>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
