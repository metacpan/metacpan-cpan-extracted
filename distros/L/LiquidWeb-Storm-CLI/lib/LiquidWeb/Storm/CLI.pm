package LiquidWeb::Storm::CLI; 

use strict;

require Exporter;
our @ISA = qw(Exporter);
our $VERSION = '1.03';

use Getopt::Long;
use HTTP::Request;
use LWP::UserAgent;
use Data::Dumper;
use MIME::Base64; 
use Text::ASCIITable; 
use JSON;

sub new {
	my $class = shift;

	my $self = bless {
		lwhome   => "$ENV{HOME}/.lw", 
		apiconfig => "$ENV{HOME}/.lw/config", 
		apisession => "$ENV{HOME}/.lw/session", 
	}, $class;

	my $options = $self->options; 

	foreach my $method (qw/help list clean/) { 
		$self->$method if ($self->{$method}); 
	} 
	
	return $self; 
}


sub configure { 
	my ($self, $args) = @_; 

	mkdir $self->{lwhome} unless -d $self->{lwhome}; 

	print "LiquidWeb API User: "; 
	chomp($self->{configure}{username} = <STDIN>); 
	print "LiquidWeb API Secret: "; 
	chomp($self->{configure}{secret} = <STDIN>);
	print "Default output type [json,perl,table]: ";  
	chomp($self->{configure}{output} = <STDIN>);

	print "Save auth credentials locally? [Y/N default No]: "; 
	chomp($self->{configure}{save} = <STDIN>);

	$self->fetchDocs;

	if (($self->{configure}{save} =~ m/y/i) ? 1 : 0) {
		$self->{configure}{output} ||= 'json'; 
		open my $session, '>', $self->{apiconfig} or die $!;
		print $session "username=$self->{configure}{username}\nsecret=$self->{configure}{secret}\noutput=$self->{configure}{output}\n";
		close $session;
		exit; 
	} 
	else {
		$self->{username} = $self->{configure}{username};
		$self->{token}    = $self->{configure}{secret};
			 
		print "Enter a timeout in seconds for this session: "; 
		chomp($self->{configure}{timeout} =  <STDIN>);
	}

	return $self->{configure}; 
}

sub fetchDocs { 
	my ($self, $args) = @_; 

	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });

	foreach my $version (qw/v1 bleed/) { 
	   my $req = HTTP::Request->new(GET => "https://www.liquidweb.com/storm/api/docs/$version/docs.json");

		my $response = $ua->request($req);
		if ($response->code != 200 || $response->content =~ /error/) {
			die($response->content);
		}

		open my $doc, '>', "$self->{lwhome}/$version.json";
		print $doc $response->content; 
	} 
} 
 
sub options { 
	my $self = shift; 

	$self->{options} ||= do { 	
		my $options; 

		my %hash = (); 
		foreach my $key (qw/output version command list/) {
			$hash{"$key=s"} = \$options->{$key};
		} 
		foreach my $key (qw/configure help clean/) {
			$hash{$key} = \$options->{$key};
		} 
		my ($inputs, $seen); 
		foreach my $version (qw/v1 bleed/) {
			my $docs = do { open my $doc, '<', "$self->{lwhome}/$version.json"; local $/; <$doc> }; 

			do {  			
				$docs = $self->parser->decode($docs);
				foreach my $class (keys %$docs) {
					foreach my $method (keys %{$docs->{$class}{__methods}}) {
						foreach my $input (keys %{$docs->{$class}{__methods}{$method}{__input}}) {
							my $value = $docs->{$class}{__methods}{$method}{__input}{$input}{type};
							 do {
								if ($value eq 'BOOLEAN') {
									$hash{$input} = \$options->{$input};
								}
								elsif ($value =~ 'HASH') {
									$hash{"$input=s%"} = \$options->{$input};
								} 
								elsif ($value =~ 'ARRAY') {
									$hash{"$input=s@"} = \$options->{$input};
								} 
								elsif ($value =~ 'INT') {
									$hash{"$input=i"} = \$options->{$input}; 
								} 
								elsif ($value =~ 'FLOAT') {
									$hash{"$input=f"} = \$options->{$input}; 
								} 
								else {
									$hash{"$input=s"} = \$options->{$input};
								} 
							} unless (!$value || $seen->{$input}++);
						} 
					} 
				}
			} unless (not $docs); 
		} 

		Getopt::Long::GetOptions(%hash); 

      if (delete $options->{configure}) {
         $self->configure;
	
			if (!$self->{configure}{save}) { 
				$options->{command} = 'account.auth.token';
			}
			
      	if (my $timeout = $self->{configure}{timeout}) {
         	$options->{timeout} = $timeout;
      	}
		} 

		foreach my $key (qw/help list command version output clean/) { 
			if (my $value = delete $options->{$key}) { 
				$self->{$key} = $value; 
			} 
		} 

		foreach my $key (keys %$options) {
			delete $options->{$key} if not defined $options->{$key}; 
		}

		$options;
	};

	return $self->{options}; 
}

sub clean { 
	my ($self, $args) = @_;

	foreach my $file (qw/apiconfig apisession/) {
		if (-e $self->{$file}) {  
			unlink $self->{$file} or die "error removing $self->{$file}: $!";
		} 
	} 
	print "Successly removed sensitive data\n";
 
	exit; 
} 

sub list { 
	my ($self, $args) = @_;

	my $commands = $self->commands;
	foreach my $version (keys %$commands) {
		foreach my $command (sort { $a cmp $b } keys %{$commands->{$version}}) {  
			if ($self->{list} eq 'all') {
				print "$command => $version\n";
			} 
			elsif($command =~ /^$self->{list}/) {
				print "$command => $version\n";
			} 
		} 	
	}
	exit;  
} 

sub commands { 
	my ($self, $args) = @_; 

	my $commands; 
	foreach my $version (qw/v1 bleed/) {
		my $docs = do {
			open my $doc, '<', "$self->{lwhome}/$version.json"; 
			local $/; <$doc>
		}; 
		do { 
			$docs = $self->parser->decode($docs);
			foreach my $class (keys %$docs) {
				my $transform = $class; 
				$transform  =~ s/\//\./g;
				foreach my $method (keys %{$docs->{$class}{__methods}}) {
					$commands->{$version}{lc $transform .'.'.$method}++;
				} 
			}
		} unless (not $docs); 
	} 

	return $commands; 
} 

sub version { 
	my ($self, $args) = @_;

	my $version = ($self->commands->{bleed}{$self->{command}}) ? 'bleed' : ($self->commands->{v1}{$self->{command}}) ? 'v1' : $self->{version}; 

	return $version; 
} 

sub buildUrl { 
	my ($self, $args) = @_;

	my $version = $self->{version} || $self->version;

	my $request = join('/', 'https://api.stormondemand.com', $version, split(/\./, $self->{command})) . '?encoding=JSON';

	return $request
}  

sub help {
	my $self = shift; 

	unless ($self->{command}) { 
my $usage=<<USAGE;
Usage: lw-cli [OPTION].. [PARAM]...[PARAM]		

  --help        displays this message
  --configure   configures the preferences for your client and syncs the database.
                  enter in values via interactive prompt, that can be reconfigured by running again.
                  each time configure mode is run, the methods database is retrieved from the api. 
  --list        lists available commands on the public api server. 
                  with 'all' argument, --list lists all available api commands.  You can specify partial commands ie. --list=billing or --list=billing.invoice
  --version     specifies the version you want to use.
                  currently only supports [v2 or bleed]. If no version is specified a lookup is performed on bleed, then v2 and uses
                  the version it finds first.
  --output      specifies the api response output type.
                  available types are [ json, text, perl, table ]. default output type is specified --during configure. 

  --clean       removes locally stored session and saved authentication credentials. 

report bugs to bug-LiquidWeb-Storm-CLI\@rt.cpan.org 

LiquidWeb homepage: http://www.liquidweb.com
General help using software: perldoc LiquidWeb::Storm::CLI 
support email: bug-LiquidWeb-Storm-CLI\@rt.cpan.org
USAGE
		print $usage; 
		exit; 
	} 
	my $version = $self->version;

	my $content = do {
		open my $docs, '<', "$self->{lwhome}/$version.json" or 
			die "Method: $self->{command} not found\n";
		local $/; <$docs>
	};

	$content = $self->parser->decode($content);

	foreach my $key (keys %$content) { 
		$content->{lc $key} = delete $content->{$key}; 
	}  

	my @parts = split(/\./,$self->{command}); 
	my $method = pop @parts; 
		
	my $query = join('/', @parts); 

	my $doc = $content->{$query}{__methods}{$method};
	
	my $params = $self->generateText($doc->{__input}); 

my $pod =<<POD; 
NAME

	$self->{command} 

DESCRIPTION

	$doc->{__description}

PARAMETERS

	$params 

POD

	print $pod; 

	exit; 
} 

sub output { 
	my $self = shift; 

	$self->{output} ||= do { 
		open my $config, '<', $self->{apiconfig};
		my $content = do { local $/; <$config> };
		my @lines = split /\n/, $content;

		foreach my $line (@lines) {
			if ($line =~ m/^([output-]+)(\s*?)=(\s*?)(.*?)$/) {
				$self->{output} = $4; 
			} 
		}

		$self->{output}; 
	}; 

	return $self->{output};  		

} 

sub auth { 
	my $self = shift; 

	do {
		if (-e $self->{apiconfig}) {
			open my $config, '<', $self->{apiconfig}; 
			my $content = do { local $/; <$config> }; 
			my @lines = split /\n/, $content; 
			foreach my $line (@lines) {
				if ($line =~ m/^([secret-]+)(\s*?)=(\s*?)(.*?)$/) {
					$self->{secret} = $4;
				} 
				if ($line =~ m/^([username-]+)(\s*?)=(\s*?)(.*?)$/) {
					$self->{username} = $4;
				}
			}
		}
		elsif (-e $self->{apisession}) {
			open my $session, '<', $self->{apisession} or die $!;
			my $cookie = do { local $/; <$session>; };
			($self->{username},$self->{secret}) = split(':', decode_base64($cookie));
		} 
	} unless ($self->{configure}{username} && $self->{configure}{secret}); 

	return { 
		username => $self->{configure}{username} ? $self->{configure}{username} : $self->{username},
		secret   => $self->{configure}{secret} ? $self->{configure}{secret} : $self->{secret}, 
	}; 
} 

sub tokenize { 
	my ($self, $args) = @_;

	open my $session, '>', $self->{apisession} or die $!;  
	print $session encode_base64("$self->{username}:$args->{token}"); 
	close $session; 

	return $self; 
}

sub display { 
	my ($self, $args) = @_; 

	my $content; 
	if ($self->output eq 'perl') { 
		print Data::Dumper->Dump([$args->{content}]); 	
	} 
	elsif ($self->output eq 'table') { 
		print $self->generateTable($args->{content});
	}
	elsif ($self->output eq 'text') { 
		print $self->generateText($args->{content}); 
	}
	else { 
		print $self->parser->encode($args->{content});
	}
	
	return $content;  
}

sub generateText { 
	my ($self, $content) = @_;

	my ($inner, $text); 
	$inner = sub {
		my $ref = shift;
		my $key = shift;

		if (ref $ref eq 'ARRAY'){
			$text .= sprintf("%s\n",($key) ? $key : '');
			$inner->($_) for @{$ref};
		}
		elsif (ref $ref eq 'HASH') {
			$text .= sprintf("%s\n", ($key) ? $key : '');
			for my $k (sort keys %{$ref}) {
				$inner->($ref->{$k},$k);
			}
		}
		elsif ($key) {
			$text .= sprintf("\t%s: %s\n", $key, $ref ? $ref : 'undef');
		}
		else {
			$text .= sprintf("\t\t%s\n", $ref);
		}
	};

	$inner->($_) for $content;

	return $text; 
}

sub generateTable {
   my ($self, $content) = @_;

	my $t; 
	my $table = Text::ASCIITable->new({ 
		allowANSI => 1, 
		headingText => $self->{command}
	});
	$t = sub {
		my $ref = shift; 
		my $key = shift; 
	
		my @keys;
		if (ref $ref eq 'ARRAY') {
			$table->addRow($ref); 
			$t->($_) for sort @{$ref};
		} 
		elsif (ref $ref eq 'HASH') {
			if (exists $ref->{items}) {
				for my $k (sort %{$ref}) { $t->($ref->{$k},$k); }
			} 
			else {
				my (@values, @keys);
				foreach my $key (sort keys %$ref) {
					push @keys, $key;
					push @values, $ref->{$key};
				} 
				$table->setCols(\@keys);
				$table->addRow(\@values);
			}
		}
	};
	$t->($_) for $content; 

	return $table; 
}
 
sub parser { 
	my ($self, $args) = @_;
 
	$self->{parser} ||= do { 
		JSON->new->utf8(1);
	};  
	return $self->{parser};  
} 
 
sub execute { 
	my ($self,  $args) = @_; 

	die "usage: lw-cli --command=class.subclass.method --param=value\n" unless ($self->{command}); 

	my $req = HTTP::Request->new(POST => $self->buildUrl);

	$req->content($self->parser->encode({ params => $self->options }));

	$req->authorization_basic($self->auth->{username}, $self->auth->{secret});

	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => $self->options->{'no-verify-ssl'} ? 0 : 1 });
	$ua->timeout($self->{apitimeout});

	my $response = $ua->request($req);

	if ($response->code != 200 || $response->content =~ /error/) {
		die($response->content);
	}

	my $content = $self->parser->decode($response->content);

	if ($content->{token}) { 
		$self->tokenize({ token => $content->{token} }); 
	}

	$self->display({ content => $content });

	return $content;
} 

1;

__END__

=head1 NAME

LiquidWeb::Storm::CLI - Perl extension for interacting with the LiquidWeb and StormOnDemand Public API.  

=head1 SYNOPSIS

use LiquidWeb::Storm::CLI;

my $client = LiquidWeb::Storm::CLI->new();

$client->execute; 

=head1 DESCRIPTION

LiquidWeb::Storm::CLI is a standalone command line utility for interfacing with the LiquidWeb and Storm on Demand public API.  This allows you to specify an api command, output format, and obtain the results directly to your terminal. Currently supported output formats are table, json, perl and text. 

=head2 Command line Synopsis 

=head3 General configuration setup. 

=over 4

lw-cli --configure

=back 

=head3 General CLI Synopsis. 

=over 4 

lw-cli --command=asset.list --output table

lw-cli --command=asset.details --uniq_id=XXRRCZ

lw-cli --command=server.create --hostname=vps.domain.com --type=DS --features option=value --features option=value --features option=value

=back 

=head3 method list and partial search. 

=over 4 

lw-cli --list all 

lw-cli --list billing.payment

=back 

=head3 help

=over 4

lw-cli --help

lw-cli --help command=server.details

=back 

=head3 Remove local auth credential store

=over 4

lw-cli --clean 

=back

=head2 new

A LiquidWeb::Storm::CLI object is constructed with the new() method

my $client = LiquidWeb::Storm::CLI->new();

Nothing can be passed to the constructor at this time. 

=head2 execute

$client->execute(); 

=head2 Notes about authentication

Using the CLI utility you will need to setup authentication during configuraton of the client.  During configuration there are two authentication options.
If you opt to save auth credentials no further interaction will be necessary, however your api username/password will be stored on the local machine. If you
choose to not save your credentials, a session cookie will be retrieved from the API which will conduct further authentication, however this session will expire
after an hour. 
 
=head1 SEE ALSO

lw-cli --help

or

perldoc LiquidWeb::Storm::CLI

=head1 BUGS

for questions, comments, feature requests or to submit bugs for this software email bug-LiquidWeb-Storm-CLI at rt.cpan.org, or thorough the web interface at
 http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LiquidWeb-Storm-CLI

=head1 AUTHOR

Matthew Terry, E<lt>mterry@liquidweb.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 (Matthew Terry) by Liquid Web Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
