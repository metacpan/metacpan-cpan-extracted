package Ganglia::Gmetric;
$VERSION=0.3;
use strict;
use base qw(Class::Accessor);
use IO::CaptureOutput qw/capture/;

=head1 NAME

Ganglia::Gmetric - perl gmetric wrapper

=head1 SYNOPSIS

  use Ganglia::Gmetric;

  my $gmetric=Ganglia::Gmetric->new({
    name => 'some name',
    value => 'some value',
    units => 'm/s',
    type => 'int16'
  });

  $gmetric->ttl('5');
  $gmetric->run(\$stdout,\$stderr);

=cut

my $gmetric='gmetric';

=head1 DESCRIPTION

Simple perl wrapper around ganglia's gmetric.

=head2 new

  my $gmetric=Ganglia::Gmetric->new;

  my $gmetric=Ganglia::Gmetric->new({name => 'some name',
    value => 'some value',
    units => 'm/s',
    type => 'int16',
    channel => 'channel',
    port => 'port',
    iface => 'iface',
    ttl => 'ttl',
    path => '/path/to/gmetric/',
});

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	return $self;
}
__PACKAGE__->mk_accessors(qw[name value type path units channel port iface ttl]);
__PACKAGE__->mk_ro_accessors(qw[command]);

=head2 run

  $gmetric->run(\$stdout,\$stderr);

runs the gmetric command. returns gmetric return code (0 on succes).

=cut
sub run {
	my $self = shift;
	my ($stdout, $stderr)=@_;
	if ($self->{path}){$gmetric=$self->{path}.$gmetric}
	my $command="$gmetric -n $self->{name} -v $self->{value} -t $self->{type}";
	if ($self->{units}){$command.=" -u $self->{units}"}
	if ($self->{channel}){$command.=" -c $self->{channel}"}
	if ($self->{port}){$command.=" -p $self->{port}"}
	if ($self->{iface}){$command.=" -i $self->{iface}"}
	if ($self->{ttl}){$command.=" -l $self->{ttl}"}
	$self->{command}=$command;
	print $self->command;
	capture sub {
		system($command);
	} => $stdout, $stderr;
	return $? >> 8;
}

1;
__END__

=head1 SEE ALSO

L<perl>.

=head1 AUTHOR

E.Vrolijk, <F<fungus@cpan.org>>.

=head1 COPYRIGHT

Copyright (c) 2008 Erik Vrolijk.  All rights reserved.
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
