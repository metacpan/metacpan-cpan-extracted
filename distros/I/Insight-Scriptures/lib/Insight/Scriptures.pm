package Insight::Scriptures;
use 5.006; use strict; use warnings;
our $VERSION = '0.04';
use JSON::Lines;
use JSON;

sub new {
	my ($pkg, $args) = @_;
	my $self = bless {
		scriptures => undef,
		scripture => undef,
		scripture_file => undef,
		index => -1,
		jsonl => JSON::Lines->new(),	
		json => JSON->new->pretty(1)->canonical,
		directory => 'directory',
		%{ $args || {} },
	}, $pkg; 
	$self->{scriptures} = $self->directory($self->{directory});
	$self->scripture($self->{scripture}) if ($self->{scripture});
	return $self;
}

sub architect {
	my ($self) = @_;

	while (1) {
		print "insight: ";
		my $in = <STDIN>;
		chomp($in);

		my %options = (
			abolish => 1,
			current => 1,
			next => 1,
			previous => 1,
			start => 1,
			end => 1,
			salvage => 1,
		);

		if ($in eq 'help') {
			print qq|
Welcome to Insight::Scriptures architect. This is a small module to assist in writing your own scriptures.

	Help:
		scripture \$scripture - loads the file containing the scripture lines
		feather \$text - extends the scripture from the current index
		abolish - deletes the current index from the scripture
		current - print the line for the current index
		next - move to the next index of the scripture and print the line
		previous - move to the previous index of the scripture and print line
		salvage - saves the scripture
		exit - quits the command line application

|;
		} elsif ($options{$in}) {
			if ($in eq 'salvage') {
				$self->$in();
				print qq|Scripture salvaged\n|;
			} else {
				my $enc = $self->{json}->encode($self->$in());
				print $self->{index} . ": " . $enc;
			}
		} elsif ($in =~ m/scripture (.*)/) {
			$self->scripture($1);
			print qq|Scripture $1 read into memory\n|;
		} elsif ($in =~ m/chapter (.*)/) {
			$self->feather( chapter => 'scripture', text => $1 );
			print qq|Chapter added to the scripture\n|;
		} elsif ($in =~ m/feather (.*)/) {
			$self->feather( text => $1 );
			print qq|Text added to the scripture\n|;
		} elsif ($in eq 'exit') {
			last;
		} else {
			print qq|Unknown options\n|;
		}
	}
}

sub compose {
	my ($self, %args) = @_; 
	
	if (! $self->{scripture} ) {
		die "Please select a scripture first before composing";
	}

	my ($chapter, $verse) = (0, 0);

	my $scripture = "";
	for (@{ $self->{scripture} }) {
		if ($_->{chapter}) {
			$chapter++;
			$scripture .= sprintf "Chapter %s - %s\n", $chapter, $_->{text};
		} else {
			$verse++;
			$scripture .= sprintf "%s:%s %s\n", $chapter, $verse, $_->{text};	
		}
	}

	print $scripture;
}

sub directory {
	my ($self, $path) = @_;

	mkdir $path if (! -d $path);

	my (@scriptures);
	opendir my $dh, $path or die "Cannot open directory for reading: $!";
	for (readdir $dh) {
		next if $_ =~ m/^\./;
		(my $scripture = $_) =~ s/\..*$//;
		push @scriptures, [$scripture, "$path/$_"]
	}
	closedir $dh;
	return \@scriptures;
}

sub scriptures {
	my ($self) = @_;
	my @scriptures;
	for (@{ $self->{scriptures} }) {
		push @scriptures, $_->[0];
	}
	return \@scriptures;
}

sub scripture {
	my ($self, $name) = @_;
	my $scripture;
	for (@{ $self->{scriptures} }) {
		if ($_->[0] =~ m/^$name$/) {
			$scripture = $_;
			last;
		}
	}

	if (! $scripture ) {
		my $file = sprintf "%s/%s.lines", $self->{directory}, $name;
		open my $fh, '>', $file or die 'Cannot open file for writing';
		print $fh "";
		close $fh;
		$scripture = [ $name, $file ];
		push @{ $self->{scriptures} }, $scripture;
		$self->{scripture} = [];
	}

	$self->{scripture_file} = $scripture;

	$scripture = $self->{jsonl}->decode_file($scripture->[-1]);

	$self->{scripture} = $scripture;
	$self->{index} = -1;

	return $scripture;
}

sub feather {
	my ($self, %args) = @_;

	$self->{index}++;

	if ($args{chapter}) {
		splice @{ $self->{scripture} }, $self->{index}, 0, \%args;
		return;
	}

	my %line = (
		time => time,
		%args,
	);
	
	splice @{ $self->{scripture} }, $self->{index}, 0, \%line;

	return \%line;
}

sub salvage {
	my ($self) = @_;
	$self->{jsonl}->encode_file($self->{scripture_file}->[-1], $self->{scripture});
	return $self;
}

sub abolish {
	my ($self) = @_;
	splice @{ $self->{scripture} }, $self->{index}, 1;
	$self->{index}--;
	return $self->current();
}

sub current {
	my ($self) = @_;
	$self->{index} = 0 if ($self->{index} < 0);
	return $self->{scripture}->[$self->{index}];
}

sub next {
	my ($self) = @_;
	$self->{index}++;
	my $next = $self->{scripture}->[$self->{index}];
	return $next;
}

sub previous {
	my ($self) = @_;
	$self->{index}--;
	return $self->{scripture}->[$self->{index}];
}

sub start {
	my ($self) = @_;
	$self->{index} = 0;
	return $self->{scripture}->[$self->{index}];
}

sub end {
	my ($self) = @_;
	$self->{index} = scalar @{ $self->{scripture} } - 1; 
	return $self->{scripture}->[$self->{index}];
}

1;

__END__

=head1 NAME

Insight::Scriptures - small module to assist in writing your own scriptures.

=head1 VERSION

Version 0.04

=cut

=head1 DESCRIPTION

I have a few modules on CPAN that were created during a period when I was in the hospital undergoing treatment for psychosis.
This module is one of them. I’ve considered removing it, but for now, I’ve decided to leave both the code and documentation as they are. 
No matter how unusual, at the time, these reflected my genuine beliefs.

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Insight::Scriptures;

	my $evil = Insight::Scriptures->new();

	$evil->scripture('Monkeys');

	$evil->feather(chapter => 1, text => 'Four Monkeys');

	$evil->feather(text => 'See no evil');

	$evil->feather(text => 'Hear no evil');

	$evil->feather(text => 'Speak no evil');

	$evil->feather(text => 'Feel no evil');

	$evil->salvage();

	...

	use Insight::Scriptures;

	my $evil = Insight::Scriptures->new(scripture => 'Monkeys');
	
	print $evil->compose();

	...

	use Insight::Scriptures;
	use feature qw/say/;

	my $evil = Insight::Scriptures->new();

	$evil->scripture('Monkeys');

	say $evil->current();

	say $evil->next();

	say $evil->previous();

	say $evil->end();

	say $evil->abolish();

	say $evil->start();

	$evil->salvage();

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-insight-scriptures at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Insight-Scriptures>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Insight::Scriptures

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Insight-Scriptures>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Insight-Scriptures>

=item * Search CPAN

L<https://metacpan.org/release/Insight-Scriptures>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Insight::Scriptures
