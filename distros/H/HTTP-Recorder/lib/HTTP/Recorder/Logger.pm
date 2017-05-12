package HTTP::Recorder::Logger;

use strict;
use warnings;
use LWP::MemberMixin;
use HTML::Entities qw(decode_entities);
our @ISA = qw( LWP::MemberMixin );

sub new {
    my $class = shift;

    my %args = (
	@_
    );

    my $self = bless ({}, ref ($class) || $class);

    $self->{'file'} = $args{'file'} || "/tmp/scriptfile";

    $self->{agentname} = "\$agent";

    return $self;
}

sub agentname { shift->_elem('agentname',      @_); }
sub file { shift->_elem('file',      @_); }

sub GetScript {
    my $self = shift;

    if (open (SCRIPT, $self->{file})) {
	my @script = <SCRIPT>;
	close SCRIPT;
	return @script;
    } else {
	return undef;
    }
}

sub SetScript {
    my $self = shift;
    my $script = shift;

    my $scriptfile = $self->{'file'};
    open (SCRIPT, ">$scriptfile");
    print SCRIPT $script;
    close SCRIPT;
}

sub Log {
    my $self = shift;
    my $function = shift;
    my $args = shift || '';

    return unless $function;
    my $line = $self->{agentname} . "->$function($args);\n";

    my $scriptfile = $self->{'file'};
    open (SCRIPT, ">>$scriptfile");
    print SCRIPT $line;
    close SCRIPT;
}

sub LogComment {
    my $self = shift;
    my $comment = shift;

    my $scriptfile = $self->{'file'};
    open (SCRIPT, ">>$scriptfile");
    print SCRIPT "# $comment\n";
    close SCRIPT;    
}

sub LogLine {
    my $self = shift;
    my %args = (
	line => "",
	@_
	);

    my $scriptfile = $self->{'file'};
    open (SCRIPT, ">>$scriptfile");
    print SCRIPT $args{line}, "\n";
    close SCRIPT;    
}

sub GotoPage {
    my $self = shift;
    my %args = (
	url => "",
	@_
	);

    $self->Log("get", "'$args{url}'");
}

sub FollowLink {
    my $self = shift;
    my %args = (
	text => "",
	index => "",
	@_
	);

    if ($args{text}) {
		$args{text} =~ s/"/\\"/g;
		# follow_link expects trimmed undecoded text, see HTTP::TokeParser::get_trimmed_text
		$args{text} =~ s/^\s+//; $args{text} =~ s/\s+$//; $args{text} =~ s/\s+/ /g;
		$args{text} = decode_entities $args{text};
		$self->Log("follow_link",  "text => '$args{text}', n => '$args{index}'");
    } else {
		$self->Log("follow_link", "n => '$args{index}'");
    }
}

sub SetFieldsAndSubmit {
    my $self = shift;
    my %args = (
		name => "",
		number => undef,
		fields => {},
		button_name => {},
		button_value => {},
		button_number => {},
		@_
		);

    $self->SetForm(name => $args{name}, number => $args{number});

    my %fields = %{$args{'fields'}};
    foreach my $field (keys %fields) {
	if ($fields{$field}{'type'} eq 'checkbox') {
	    $self->Check(name => $fields{$field}{'name'}, 
			 value => $fields{$field}{'value'});
	} else {
	    $self->SetField(name => $fields{$field}{'name'}, 
			    value => $fields{$field}{'value'});
	}
    }
    # use click instead of submit
    $self->Click(name => $args{name}, 
		  button_name => $args{button_name},
		  button_value => $args{button_value},
		  button_number => $args{button_number},
		  );
}

sub SetForm {
    my $self = shift;
    my %args = (
	@_
	);

    if ($args{name}) {
	$self->Log("form_name", "'$args{name}'");
    } else {
	$self->Log("form_number", $args{number});
    }
}

sub SetField {
    my $self = shift;
    my %args = (
		name => undef,
		value => '',
		@_
		);

    return unless $args{name};

    # escape single quotes
    $args{name} =~ s/'/\\'/g;
	$args{value} = '' if !defined($args{value});
    $args{value} =~ s/'/\\'/g;

    $self->Log("field", "'$args{name}', '$args{value}'");
}

sub Check {
    my $self = shift;
    my %args = (
		name => undef,
		value => undef,
		@_
		);

    return unless $args{name} && $args{value};

    # escape single quotes
    $args{name} =~ s/'/\\'/g;
    $args{value} =~ s/'/\\'/g;

    $self->Log("tick", "'$args{name}', '$args{value}'");
}

sub UnCheck {
    my $self = shift;
    my %args = (
		name => undef,
		value => undef,
		@_
		);

    return unless $args{name} && $args{value};

    # escape single quotes
    $args{name} =~ s/'/\\'/g;
    $args{value} =~ s/'/\\'/g;

    $self->Log("untick", "'$args{name}', '$args{value}'");
}

sub Submit {
    my $self = shift;
    my %args = (
	@_
	);

    my $submitargs = '';
    if ($args{name}) {
	$submitargs = "form_name => '$args{name}', ";
    } elsif ($args{number}) {
	$submitargs = "form_number => '$args{number}'";
    }

    $submitargs .= ', ' if $submitargs;

    if ($args{button_name}) {
	$submitargs .= "button => $args{button_name}";
    }

    # TODO: also support button value, number
    # Don't add this until WWW::Mechanize supports it

    $self->Log("submit_form", $submitargs);
}

sub Click {
    my $self = shift;
    my %args = (
	@_
	);
    
    my $clickargs;
    if ($args{button_name}) {
	$clickargs = "'$args{button_name}'";
    }

    # TODO: also support button value, number
    # Don't add this until WWW::Mechanize supports it
    $self->Log("click", $clickargs);
}

1;
