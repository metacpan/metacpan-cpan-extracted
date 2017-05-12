# Copyright (C) 2008 Wes Hardaker
# License: Same as perl.  See the LICENSE file for details.
package Ham::Callsign::Base;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(Warn Debug);

sub new {
    my $type = shift;
    my ($class) = ref($type) || $type;
    my $self = {};
    %$self = @_;
    bless($self, $class);
    $self->read_config();
    $self->init();
    return $self;
}

sub init {
    # noop ..  overridden by other clasess when needed
}

sub read_config {
    my $self = shift;
    my $configfile = $self->{'callsignrc'} || $ENV{'CALLSIGNRC'} ||
      $ENV{'HOME'} . "/.callsignrc";
    return if (! -f $configfile);
    Debug("reading $configfile\n");
    open(I,$configfile);
    while (<I>) {
	next if (/^\s*#/);
	if (/^([^:]+):\s*(.*)/) {
	    $self->{$1} = $2;
	}
    }
    close(I);
}

sub Warn {
    warn @_;
}

sub Debug {
    return;
    print @_;
}

1;
