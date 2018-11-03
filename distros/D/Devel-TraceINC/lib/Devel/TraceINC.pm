use 5.008;
use strict;
use warnings;

package Devel::TraceINC;
our $VERSION = '1.100852';
# ABSTRACT: Trace who is loading which perl modules

# a base package for sticky arrays; see this on CPAN
BEGIN {
    package              # newline to hide this inline package from the PAUSE indexer
      Array::Sticky;

    sub TIEARRAY {
      my ($class, %args) = @_;

      my $self = bless +{
        head => [ @{ $args{head} || [] } ],
        body => [ @{ $args{body} || [] } ],
        tail => [ @{ $args{tail} || [] } ],
      }, $class;

      return $self;
    }

    sub POP { pop @{shift()->{body}} }
    sub PUSH { push @{shift()->{body}}, @_ }
    sub SHIFT { shift @{shift()->{body}} }
    sub UNSHIFT { unshift @{shift()->{body}}, @_ }

    sub CLEAR {
      my ($self) = @_;
      @{$self->{body}} = ();
    }
    sub EXTEND {}
    sub EXISTS {
      my ($self, $index) = @_;
      my @serial = $self->serial;
      return exists $serial[$index];
    }

    sub serial {
      my ($self) = @_;
      return map { @{$self->{$_}} } qw(head body tail);
    }

    sub STORE {
      my ($self, $index, $value) = @_;
      $self->{body}[$index] = $value;
    }

    sub SPLICE {
      my $self = shift;
      my $offset = shift || 0;
      my $length = shift; $length = $self->FETCHSIZE if ! defined $length;

      # avoid "splice() offset past end of array"
      no warnings;

      return splice @{$self->{body}}, $offset, $length, @_;
    }

    sub FETCHSIZE {
      my $self = shift;

      my $size = 0;
      my %size = $self->sizes;

      foreach (values %size) {
        $size += $_;
      }

      return $size;
    }

    sub sizes {
      my $self = shift;
      return map { $_ => scalar @{$self->{$_}} } qw(head body tail);
    }

    sub FETCH {
      my $self = shift;
      my $index = shift;

      my %size = $self->sizes;

      foreach my $slot (qw(head body tail)) {
        if ($size{$slot} > $index) {
          return $self->{$slot}[$index];
        } else {
          $index -= $size{$slot};
        }
      }

      return $self->{body}[$size{body} + 1] = undef;
    }
}

# also from CPAN
BEGIN {
    package              # newline to hide this inline package from the PAUSE indexer
			Array::Sticky::INC;

    sub make_sticky { tie @INC, 'Array::Sticky', head => [shift @INC], body => [@INC] }
}

# At last, the code we care about
BEGIN {
    unshift @INC, sub {
        my ($self, $file) = @_;
        my ($package, $filename, $line) = caller;
        warn "$file loaded from package $package, file $filename, line $line\n";
        return;    # undef to indicate that require() should look further
    };
    Array::Sticky::INC->make_sticky;
}

1;

__END__

=head1 NAME

Array::Sticky::INC - lock your @INC hooks in place

=head1 SYNOPSIS

Let's say you've written a module which hides the existence of certain modules:

    package Module::Hider;

    my %hidden;
    my $set_up_already;

    sub hider {
        my ($module) = pop();
        $module =~ s{/}{::}g;
        $module =~ s{\.pm$}{};

        return undef if exists $hidden{$module};
    }

    sub import {
        my ($class, @to_hide) = @_;

        @hidden{@to_hide} = @to_hide;
        if (! $set_up_already++) {
            # this works until some other piece of code issues a
            #     use lib '/somewhere';
            # or
            #     unshift @INC, '/over';
            # or
            #     $INC[0] = '/the-rainbow';
            unshift @INC, \&hider;
        }
    }

    1;

To hide a module using this Module::Hider, you'd write:

    use Module::Hider qw(strict warnings LWP::UserAgent);

Now any code which is running with that in place would encounter errors
attempting to load strict.pm, warnings.pm, and LWP/UserAgent.pm.

Hiding modules is pretty nice; see L<Devel::Hide> for a stronger treatment of why
you might care to do so.

But there is one downside to the "stick a coderef in @INC" trick: if any piece of
code manually updates @INC to steal the primary spot away from your coderef, then
your coderef may be rendered ineffective.

This module provides a simple interface to tie @INC in a way that you specify so
that attempts to manipulate @INC succeed in a way that you choose.

Now you may write Module::Hider like this:


    package Module::Hider;

    use Array::Sticky::INC;

    my %hidden;
    my $set_up_already;

    sub hider {
        my ($module) = pop();
        $module =~ s{/}{::}g;
        $module =~ s{\.pm$}{};

        return undef if exists $hidden{$module};
    }

    sub import {
        my ($class, @to_hide) = @_;

        @hidden{@to_hide} = @to_hide;
        if (! $set_up_already++) {
            unshift @INC, \&hider;
            Array::Sticky::INC->make_sticky;
        }
    }

    1;

=head1 RECIPES

This module only makes the foremost element of @INC sticky. If you need to make different elements of @INC sticky,
then use L<Array::Sticky>:

=head2 Making the tail of @INC sticky

If you're using like L<The::Net> or L<Acme::Intraweb> to automatically install modules that you're missing,
then you might want to lock their behaviors to the end of @INC:

    package My::The::Net;

    use The::Net;
    use Array::Sticky;

    sub import {
        tie @INC, 'Array::Sticky', body => [@INC], tail => [shift @INC];
    }

=head1 SEE ALSO

=over 4

=item * L<Devel::INC::Sorted> solves this same problem slightly differently.

=item * 'perldoc -f require' and 'perldoc perltie' talk about code hooks in @INC, and tied arrays, respectively

=item * L<Acme::Intraweb> - places a coderef at the tail of @INC

=item * L<The::Net> - places a coderef at the tail of @INC

=item * L<Devel::Hide> - places a coderef at the head of @INC

=item * L<Test::Without::Module> - places a coderef at the head of @INC

=back

=head1 BUGS AND LIMITATIONS

If you do something like:

    local @INC = @INC;
    unshift @INC, '/some/path';

then this module won't be able to preserve your hooks at the head of @INC.

Please report bugs on this project's Github Issues page: L<http://github.com/belden/perl-array-sticky/issues>.

=head1 CONTRIBUTING

The repository for this software is freely available on this project's Github page:
L<http://github.com/belden/perl-array-sticky>. You may fork it there and submit pull requests in the standard
fashion.

=head1 COPYRIGHT AND LICENSE

    (c) 2013 by Belden Lyman

This library is free software: you may redistribute it and/or modify it under the same terms as Perl
itself; either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.

}


1;


__END__
=pod

=for test_synopsis 1;
__END__

=head1 NAME

Devel::TraceINC - Trace who is loading which perl modules

=head1 VERSION

version 1.100850

=head1 SYNOPSIS

    $ perl -MDevel::TraceINC t/01_my_test.t
    Test/More.pm loaded from package main, file t/01_my_test.t, line 6
    Test/Builder/Module.pm loaded from package Test::More, file /usr/local/svn/perl/Test/More.pm, line 22
    Test/Builder.pm loaded from package Test::Builder::Module, file /usr/local/svn/perl/Test/Builder/Module.pm, line 3
    Exporter/Heavy.pm loaded from package Exporter, file /System/Library/Perl/5.8.6/Exporter.pm, line 17
    ...

=head1 DESCRIPTION

I had a situation where a program was loading a module but I couldn't find
where in the code it was loaded. It turned out that I loaded some module,
which loaded another module, which loaded the module in question. To be
able to track down who loads what, I wrote Devel::TraceINC.

Just C<use()> the module and it will print a warning every time a module is
searched for in C<@INC>, i.e., loaded.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Devel-TraceINC>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Devel-TraceINC/>.

The development version lives at
L<http://github.com/marcelgrunauer/Devel-TraceINC/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

