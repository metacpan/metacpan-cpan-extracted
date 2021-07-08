package KelpX::Symbiosis::Test;

our $VERSION = '1.12';

use Kelp::Base;
use Kelp::Test;

attr "-app" => sub { die "`app` parameter is required" };

sub wrap
{
	my ($class, %args) = @_;
	my $self = $class->new(%args);
	return Kelp::Test->new(app => $self);
}

sub run
{
	shift->app->run_all(@_);
}

sub can
{
	my ($self, $func) = @_;

	if (ref $self) {
		my $can = $self->app->can($func);
		return $can if defined $can;
	}

	return $self->SUPER::can($func);
}

sub AUTOLOAD
{
	my ($self) = shift;

	my $func = our $AUTOLOAD;
	return if $func =~ /::DESTROY$/;
	$func =~ s/.*:://;

	my $method = $self->app->can($func);
	die "Kelp cannot $func" unless $method;
	$method->($self->app, @_);
}

1;
__END__

=head1 NAME

KelpX::Symbiosis::Test - Allow testing symbiotic environments using Kelp::Test

=head1 SYNOPSIS

	# in test file
	use KelpX::Symbiosis::Test;

	my $t = KelpX::Symbiosis::Test->wrap(app => $kelp_app);

	# continue testing using $t, just like Kelp::Test

=head1 DESCRIPTION

This module allows testing Kelp apps with Symbiosis using L<Kelp::Test>. The problem with I<Kelp::Test> is that it automatically runs I<run()> on the app without any way to configure this behavior. Symbiotic apps use I<run_all()> to run the whole environment, while I<run()> stays the same and only runs Kelp. This module replaces those two methods and autoloads the rest of the methods from Kelp instance.

=head1 USAGE

=head2 wrap

I<new in 1.10>

Instead of using I<Kelp::Test::new> use I<KelpX::Symbiosis::Test::wrap> with the same interface. Then you can create test cases not only for Kelp routes but also for the rest of Plack applications. The I<wrap> method will return a L<Kelp::Test> object, so refer to its documentation for more details.

=head1 HOW DOES IT WORK?

The main Kelp instance is wrapped in this module class and the resulting object is passed into Kelp::Test instead. I<KelpX::Symbiosis::Test> autoloads Kelp methods and wraps I<run_all> inside I<run>, which allows L<Kelp::Test> to use it.
