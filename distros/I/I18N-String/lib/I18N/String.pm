package I18N::String;
{
  $I18N::String::VERSION = '0.03';
}

use strict;
use warnings;
use Carp;

our $Localize = sub {@_};

use overload
    q{""}    => \&_stringify,
    q{0+}    => \&_stringify,
    fallback => 1;

#===================================
sub new {
#===================================
    my $class  = shift;
    my $string = shift;
    return bless( \$string, $class );
}

#===================================
sub _stringify {
#===================================
    no warnings;
    local $^W = 0;
    $Localize->( ${ $_[0] } );
}

#===================================
sub loc {
#===================================
    my $self = shift;
    $Localize->( ${$self}, @_ );
}

#===================================
sub localize_via {
#===================================
    my $class = shift;
    my $sub = shift or croak "No localizer passed to localize_via()";
    croak "localize_via() expects a code-ref"
        unless ref $sub eq 'CODE';
    $Localize = $sub;
}

#===================================
sub import {
#===================================
    my $class  = shift;
    my $caller = caller;
    my $name   = shift || 'loc';
    {
        no strict 'refs';
        *{"${caller}::${name}"}
            = $name eq '_'
            ? sub { @_ ? $class->new(@_) : \*_ }
            : sub { $class->new(@_) }
    }
}

1;

# ABSTRACT: Delay I18N translation until a variable is stringified


__END__
=pod

=head1 NAME

I18N::String - Delay I18N translation until a variable is stringified

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use I18N::String qw('_');

    I18N::String->localize_via( \&localize );

    my @Days = (
        _('Monday'),   _('Tuesday'),  _('Wednesday'),
        _('Thursday'), _('Friday'),   _('Saturday'),
        _('Sunday')
    );

    sub day_of_week {
        my $day = shift;
        return $Days[$day]
    }

=head1 DESCRIPTION

Sometimes it is useful to store I18N'able strings in variables, but delay
their translation until the point that they are actually used. L<I18N::String>
does this for you.

=head1 USAGE

=head2 Importing

    use I18N::String;           # exports loc()
    use I18N::String 'foo'      # exports a func named foo()


    my $str = foo('String');

    print $str;                 # localized version of 'String'

=head2 localize_via()

    I18N::String->localize_via( $coderef );

You need to set this once, and it is global.  This is the function that will
be called when your variable is stringified, to return the localized version.

=head2 loc()

You can also store strings that require arguments, eg:

    $str = _('I found [quant,_1,file,files]');

And stringify them via:

    $str->loc(@args);

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc I18N::String

You can also look for information at:

=over

=item * GitHub

L<http://github.com/clintongormley/I18N-String>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/I18N-String>

=item * Search MetaCPAN

L<https://metacpan.org/module/I18N-String>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

