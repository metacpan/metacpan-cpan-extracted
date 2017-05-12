package FormValidator::Simple::Plugin::V8;

use strict;
use warnings;

our $VERSION = '0.01';


use JavaScript::V8;
use File::Slurp;

sub import {
	my $class   = shift;
	my $package = caller(0);

	no strict 'refs';
	no warnings 'once';

	my $rules = read_file(shift);

	my $context = JavaScript::V8::Context->new;

	$context->eval(q{
		function rule (name, func) {
			rule[name] = func;
			_register(name);
		}
	});

	$context->bind(_register => sub {
		my $name = shift;
		*{ $package . "::$name"} = validate($context, $name);
		1;
	});

	$context->bind(log => sub {
		use Data::Dumper;
		warn Dumper @_ ;
		1;
	});

	$context->eval($rules);

	${"$package\::context"} = $context;
}

sub validate {
	my ($context, $name) = @_;
	sub {
		my ($class, @args) = @_;
		$context->bind(func  => $name);
		$context->bind(args => \@args);
		my $ret = $context->eval("rule[func].apply(null, args)");
		if ($@) {
			die $@;
		}
		!!$ret;
	};
}


1;
__END__

=encoding utf8

=head1 NAME

FormValidator::Simple::Plugin::V8 - Enable to write validation rules in JavaScript

=head1 SYNOPSIS

  package FormValidator::Simple::Plugin::MyRules;
  use FormValidator::Simple::Plugin::V8 'rules.js';

  use FormValidator::Simple qw/MyRules/;

  my $result = FormValidator::Simple->check( ... );

=head1 DESCRIPTION

FormValidator::Simple::Plugin::V8 is for commonalizing validation between client and server.

=head1 API in JavaScript

=over 4

=item rule(name, func);

name is validation rule name and func is function which returns true/false.

=back

=head1 AUTHOR

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
