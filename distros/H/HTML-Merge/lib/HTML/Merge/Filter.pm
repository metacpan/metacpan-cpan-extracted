package HTML::Merge::Filter;
use Tie::Handle;
use strict qw(subs vars);
use vars qw(@ISA);

@ISA = qw(Tie::Handle);

my $min = length($HTML::Merge::Ini::MERGE_SCRIPT);

sub TIEHANDLE {
	my ($class, $engine, $out) = @_;
	unless (UNIVERSAL::isa($out, 'GLOB')) {
		$out = \*{$out};
	}
	my $self = {'engine' => $engine, 'out' => $out,	
		'id' => undef};
	bless $self, $class;
}

sub WRITE {
	my ($self, $scalar, $length, $offset) = @_;
	$offset ||= 0;
	$length ||= length($scalar);
	my $towrite = substr($scalar, $offset, $length);
	$self->{'buffer'} .= $towrite;
	return if length($self->{'buffer'}) < $min;
	my $out = substr($self->{'buffer'}, 0, -$min);
	$self->{'buffer'} = substr($self->{'buffer'}, -$min);
	my $id = $self->ID;
	$out =~ s{ (?<!\w) ($HTML::Merge::Ini::MERGE_SCRIPT) (?!\w)
		}{$1/$id}xg;
	my $fh = $self->{'out'};
	print $fh $out;
}

sub DESTROY {
	$_[0]->Close;
}

sub Close {
	my $self = shift;
	my $fh = $self->{'out'};
	my $out = $self->{'buffer'};
	my $id = $self->ID;
	$out =~ s{ (?<!\w) ($HTML::Merge::Ini::MERGE_SCRIPT) (?!\w)
		}{$1/$id}xg;
	print $fh $out;
	$self->{'buffer'} = '';
}

sub ID {
	my $self = shift;
	return $self->{'id'} if $self->{'id'};
	my $engine = $self->{'engine'};
	$engine->GetSessionID;
	return $self->{'id'} = $engine->{'session_id'};
}
1;
