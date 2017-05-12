#
# Mail::SPF::Test::Base
# Base class for Mail::SPF::Test classes.
#
# (C) 2006 Julian Mehnle <julian@mehnle.net>
# $Id: Base.pm 27 2006-12-23 20:11:21Z Julian Mehnle $
#
##############################################################################

package Mail::SPF::Test::Base;

=head1 NAME

Mail::SPF::Test::Base - Base class for Mail::SPF::Test classes

=cut

use warnings;
use strict;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use base 'Mail::SPF::Test::Base';
    
    sub new {
        my ($class, @options) = @_;
        my $self = $class->SUPER::new(@options);
        ...
        return $self;
    }

=head1 DESCRIPTION

B<Mail::SPF::Test::Base> is a common base class for all B<Mail::SPF::Test>
classes.

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Test::Base>

Creates a new object of the class on which the constructor was invoked.  The
provided options are stored as key/value pairs in the new object.

The C<new> constructor may also be called on an object, in which case the
object is cloned.  Any options provided override those from the old object.

There are no common options defined in B<Mail::SPF::Test::Base>.

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
    not ref($class)
        or die('Class method called as an instance method');
    my $accessor_name = "${class}::${name}";
    my $accessor;
    if ($readonly) {
        $accessor = sub {
            local *__ANON__ = $accessor_name;
            my ($self, @value) = @_;
            ref($self)
                or die('Instance method called as a class method');
            not @value
                or die("$accessor_name is read-only");
            return $self->{$name};
        };
    }
    else {
        $accessor = sub {
            local *__ANON__ = $accessor_name;
            my ($self, @value) = @_;
            ref($self)
                or die('Instance method called as a class method');
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

There are no common instance methods defined in B<Mail::SPF::Test::Base>.

=head1 SEE ALSO

L<Mail::SPF::Test>

For availability, support, and license information, see the README file
included with Mail::SPF::Test.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
