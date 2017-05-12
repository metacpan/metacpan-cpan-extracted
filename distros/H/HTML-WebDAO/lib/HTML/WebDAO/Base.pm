#$Id: Base.pm 338 2008-09-28 13:14:54Z zag $

package HTML::WebDAO::Base;

use Data::Dumper;
use Carp;
@HTML::WebDAO::Base::ISA    = qw(Exporter);
@HTML::WebDAO::Base::EXPORT = qw(attributes sess_attributes);

$DEBUG = 0;    # assign 1 to it to see code generated on the fly

sub sess_attributes {
    my ($pkg) = caller;
    shift if $_[0] =~ /\:\:/ or  $_[0] eq $pkg;
    croak "Error: attributes() invoked multiple times"
      if scalar @{"${pkg}::_SESS_ATTRIBUTES_"};
    @{"${pkg}::_SESS_ATTRIBUTES_"} = @_;#grep { !/^_+/ } @_;
    my $code = "";
    print STDERR "Creating methods for $pkg\n" if $DEBUG;
    foreach my $attr (@_) {
        print STDERR "  defining method $attr\n" if $DEBUG;

        # If the accessor is already present, give a warning
        if ( UNIVERSAL::can( $pkg, "$attr" ) ) {
            carp "$pkg already has method: $attr";
            next;
        }

#    $code .= (UNIVERSAL::can($pkg,"__define_accessor")) ? __define_accessor ($pkg, $attr):_define_accessor ($pkg, $attr);
        $code .= _define_accessor( $pkg, $attr );
    }

    #  $code .= _define_constructor($pkg);
    eval $code;
    if ($@) {
        die "ERROR defining and attributes for '$pkg':"
          . "\n\t$@\n"
          . "-----------------------------------------------------"
          . $code;
    }
}



sub attributes {
    my ($pkg) = caller;
    shift if $_[0] =~ /\:\:/ or  $_[0] eq $pkg;
    my $code = "";
    foreach my $attr (@_) {
        print STDERR "  defining method $attr\n" if $DEBUG;

        # If the accessor is already present, give a warning
        if ( UNIVERSAL::can( $pkg, "$attr" ) ) {
            carp "$pkg already has rtl method: $attr";
            next;
        }
        $code .= _define_accessor( $pkg, $attr );
    }
    eval $code;
    if ($@) {
        die "ERROR defining  rtl_attributes for '$pkg':"
          . "\n\t$@\n"
          . "-----------------------------------------------------"
          . $code;
    }

}

sub _define_accessor {
    my ( $pkg, $attr ) = @_;

    # qq makes this block behave like a double-quoted string
    my $code = qq{
    package $pkg;
    sub $attr {                                      # Accessor ...
      my \$self=shift;
      \@_ ? \$self->set_attribute("$attr",shift):\$self->get_attribute("$attr");
    }
  };
    $code;
}

sub _define_constructor {
    my $pkg  = shift;
    my $code = qq {
    package $pkg;
    sub new {
	my \$class =shift;
	my \$self={};
	my \$stat;
	bless (\$self,\$class);
	return (\$stat=\$self->_init(\@_)) ? \$self: \$stat;
#	return \$self if (\$self->_init(\@_));
#	return (\$stat=\$self->Error) ? \$stat : "Error initialize";
    }
  };
    $code;
}

sub get_attribute_names {
    my $pkg = shift;
    $pkg = ref($pkg) if ref($pkg);
    my @result = @{"${pkg}::_SESS_ATTRIBUTES_"};
    if ( defined( @{"${pkg}::ISA"} ) ) {
        foreach my $base_pkg ( @{"${pkg}::ISA"} ) {
            push( @result, get_attribute_names($base_pkg) );
        }
    }
    @result;
}

sub set_attribute {
    my ( $obj, $attr_name, $attr_value ) = @_;
    $obj->{"Var"}->{$attr_name} = $attr_value;
}

#
sub get_attribute {
    my ( $self, $attr_name ) = @_;
    return $self->{"Var"}->{$attr_name};
}

# $obj->set_attributes (name => 'John', age => 23);
# Or, $obj->set_attributes (['name', 'age'], ['John', 23]);
sub set_attributes {
    my $obj = shift;
    my $attr_name;
    if ( ref( $_[0] ) ) {
        my ( $attr_name_list, $attr_value_list ) = @_;
        my $i = 0;
        foreach $attr_name (@$attr_name_list) {
            $obj->$attr_name( $attr_value_list->[ $i++ ] );
        }
    }
    else {
        my ( $attr_name, $attr_value );
        while (@_) {
            $attr_name  = shift;
            $attr_value = shift;
            $obj->$attr_name($attr_value);
        }
    }
}

# @attrs = $obj->get_attributes (qw(name age));
sub get_attributes {
    my $obj = shift;
    my (@retval);
    map { $obj->$_() } @_;
}

sub new {
    my $class = shift;
    my $self  = {};
    my $stat;
    bless( $self, $class );
    return ( $stat = $self->_init(@_) ) ? $self : $stat;
}

sub _init {
    my $self = shift;
    return 1;
}

#put message into syslog
sub _deprecated {
    my $self       = shift;
    my $new_method = shift;
    my ( $old_method, $called_from_str, $called_from_method ) =
      ( ( caller(1) )[3], ( caller(1) )[2], ( caller(2) )[3] );
    $self->_log3(
"called deprecated method $old_method from $called_from_method at line $called_from_str. Use method $new_method instead."
    );
}

sub logmsgs {
    my $self = shift;
    $self->_deprecated("_log1,_log2");
    $self->_log1(@_);
}
sub _log1 { my $self = shift; $self->_log( level => 1, par => \@_ ) }
sub _log2 { my $self = shift; $self->_log( level => 2, par => \@_ ) }
sub _log3 { my $self = shift; $self->_log( level => 3, par => \@_ ) }
sub _log4 { my $self = shift; $self->_log( level => 4, par => \@_ ) }
sub _log5 { my $self = shift; $self->_log( level => 5, par => \@_ ) }

sub _log {
    my $self = shift;
    my %args = @_;
    my ($mod_sub,$str) = (caller(2))[3,2];
    ($str) = (caller(1))[2];
    print STDERR "$$ [$args{level}] $mod_sub:$str  @{$args{par}} \n";
}

sub LOG {
    my $self = shift;
    $self->_deprecated("_log1,_log2");
    return $self->logmsgs(@_);
}
1;
