package Full::Class;

use Full::Pragmata qw(:v1);
use parent qw(Full::Pragmata);

our $VERSION = '1.004'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=encoding utf8

=head1 NAME

Full::Class - common pragmata for modules which provide an OO class

=head1 SYNOPSIS

 package Example::Class;
 use Full::Class qw(:v1);

 async method startup {
  $log->infof('Starting %s', __PACKAGE__);
 }

 1;

=head3 Method parameter constraints

These use L<Signature::Attribute::Checked> to provide method parameter checks.
Note that the C<extended> keyword is required, see L<Sublike::Extended> for more information.

 package Example;
 use Full::Class qw(:v1);
 extended method example ($v :Checked(Num)) { }

=head2 Class features

The calling package will be marked as an L<Object::Pad> class, providing the
L<Object::Pad/method>, L<Object::Pad/has> and C<async method> keywords.

This also makes available a L<Log::Any> instance in the C<$log> package variable,
and for L<OpenTelemetry> support you get C<$tracer> as an L<OpenTelemetry>
instance.

It's very likely that future versions will bring in new functionality or
enable/disable a different featureset. This behaviour is controlled through
mandatory version tags:

 use Full::Class qw(:v1);

The latest available version is C<:v1>.

=cut

use Object::Pad;
use Object::Pad qw(:experimental(mop));

sub import ($called_on, $version, %args) {
    my $class = __PACKAGE__;
    my $pkg = $args{target} // caller(0);

    $class->next::method($version, target => $pkg);
    if(my $class = $args{class} // $pkg) {
        Object::Pad->import_into($pkg, ":experimental(init_expr mop custom_field_attr)");

        my $method = 'begin_' . ($args{type} || 'class');
        Module::Load::load($args{extends}) if $args{extends};
        my $meta = Object::Pad::MOP::Class->$method(
            $class,
            (
                $args{extends}
                ? (extends => $args{extends})
                : ()
            ),
        );
        $args{does} = [ $args{does} // () ] unless ref $args{does};
        for my $role ($args{does}->@*) {
            Module::Load::load($role) unless eval { Object::Pad::MOP::Class->for_class($role) };
            $meta->add_role($role);
        }
        return $meta;
    }
    return $pkg;
}

1;

__END__

=head1 AUTHOR

Original code can be found at https://github.com/deriv-com/perl-Myriad/tree/master/lib/Myriad/Class.pm,
by Deriv Group Services Ltd. C<< DERIV@cpan.org >>. This version has been split out as a way to provide
similar functionality.

=head1 LICENSE

Released under the same terms as Perl itself.

