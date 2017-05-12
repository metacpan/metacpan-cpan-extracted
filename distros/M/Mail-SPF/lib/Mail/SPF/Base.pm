#
# Mail::SPF::Base
# Base class for Mail::SPF classes.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Base.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Base;

=head1 NAME

Mail::SPF::Base - Base class for Mail::SPF classes

=cut

use warnings;
use strict;

use Error ':try';

use Mail::SPF::Exception;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use base 'Mail::SPF::Base';

    sub new {
        my ($class, @options) = @_;
        my $self = $class->SUPER::new(@options);
        ...
        return $self;
    }

=head1 DESCRIPTION

B<Mail::SPF::Base> is a common base class for all B<Mail::SPF> classes.

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Base>

Creates a new object of the class on which the constructor was invoked.  The
provided options are stored as key/value pairs in the new object.

The C<new> constructor may also be called on an object, in which case the
object is cloned.  Any options provided override those from the old object.

There are no common options defined in B<Mail::SPF::Base>.

=cut

sub new {
    my ($self, %options) = @_;
    my $new =
        ref($self) ?              # Was new() invoked on a class or an object?
            { %$self, %options }  # Object: clone source object, override fields.
        :   \%options;            # Class:  create new object.
    return bless($new, $self->class);
}

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<class>: returns I<string>

Returns the class name of the class or object on which it is invoked.

=cut

sub class {
    my ($self) = @_;
    return ref($self) || $self;
}

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<make_accessor($name, $readonly)>: returns I<code-ref>

Creates an accessor method in the class on which it is invoked.  The accessor
has the given name and accesses the object field of the same name.  If
$readonly is B<true>, the accessor is made read-only.

=cut

sub make_accessor {
    my ($class, $name, $readonly) = @_;
    throw Mail::SPF::EClassMethod if ref($class);
    my $accessor_name = "${class}::${name}";
    my $accessor;
    if ($readonly) {
        $accessor = sub {
            local *__ANON__ = $accessor_name;
            my ($self, @value) = @_;
            throw Mail::SPF::EInstanceMethod if not ref($self);
            throw Mail::SPF::EReadOnlyValue("$accessor_name is read-only") if @value;
            return $self->{$name};
        };
    }
    else {
        $accessor = sub {
            local *__ANON__ = $accessor_name;
            my ($self, @value) = @_;
            throw Mail::SPF::EInstanceMethod if not ref($self);
            $self->{$name} = $value[0] if @value;
            return $self->{$name};
        };
    }
    {
        no strict 'refs';
        *{$accessor_name} = $accessor;
    }
    return $accessor;
}

=back

=head2 Instance methods

There are no common instance methods defined in B<Mail::SPF::Base>.

=head1 SEE ALSO

L<Mail::SPF>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
