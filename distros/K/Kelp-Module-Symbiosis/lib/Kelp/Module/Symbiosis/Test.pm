package Kelp::Module::Symbiosis::Test;

our $VERSION = '1.01';

use Kelp::Base;

attr "-app" => sub { die "`app` parameter is required" };

sub run
{
	shift->app->run_all(@_);
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

Kelp::Module::Symbiosis::Test - Allow testing symbiotic environments using Kelp::Test

=head1 SYNOPSIS

	# in test file
	use Kelp::Module::Symbiosis::Test;

	my $app = Kelp::Module::Symbiosis::Test->new(app => $kelp_app);
	my $t = Kelp::Test->new(app => $app);

	# continue testing using $t

=head1 DESCRIPTION

This module allows testing Kelp apps with Symbiosis using L<Kelp::Test>. The problem with Kelp::Test is that it automatically runs I<run()> on the app without any way to configure this behavior. Symbiotic apps use I<run_all()> to run the whole environment, while I<run()> stays the same and only runs Kelp. This module replaces those two methods and autoloads the rest of the methods from Kelp instance.

=head1 USAGE

Before passing the main Kelp instance into Kelp::Test wrap it in this module using the constructor and pass the resulting application instead. Then you can create test cases not only for Kelp routes but also for the rest of Plack applications.
