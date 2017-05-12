package Jaipo::UI::Console;
use warnings;
use strict;
use Jaipo;
use utf8;
use feature qw(:5.10);
use Term::ReadLine;
use Time::HiRes qw( setitimer ITIMER_REAL ITIMER_PROF time );

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

=encoding utf8

=head1 SYNOPSIS

to enter Jaipo console:

    $ jaipo console

    > use Twitter           # enable Twitter service plugin
    > use Plurk             # enable Plurk service plugin
    > use RSS               # enable RSS plugin
    > use IRC               # enable IRC plugin

Jaipo will automatically save your configuration, you only need to use 'use'
at first time.

to update status

    > :突然下起大雨。

to read all messeges
    > r

    Service |   User   | Message
    twitter    c9s       oh hohoho !
    plurk      xxx       剛喝完咖啡.
    ...
    ...
    ...

to read messages on Jaiku.com

    > jaiku r

to read someone's messages on Jaiku.com

    > jaiku r UnitedNation

to read public timeline

    > p

to check user's profile

    > jaiku w IsYourDaddy

setup location on Jaiku

    > jaiku l 我在墾丁，天氣情。

to update post to Twitter

    > twitter :雨停了

to reply to someone's post on Twiwter

    > twitter reply Someone 呆丸朱煮好棒

to send direct message to someone on twitter

    > twitter send mama 媽，我阿雄啦！

to follow someone on twitter

    > twitter follow mama

to send a message to a channel on Jaiku

    > jaiku #TVshow 媽，我上電視了！(揮手)

create a regular expression filter for twitter timeline

    > filter /cor[a-z]*s/i  :twitter

enter service-only mode

    > only twitter
    :twitter>

    > only jaiku
    :jaiku>


=head1 Command Reference

=head2 Global Commands

=item m

read user updates

=item p  

read friend updates

=item g  

read global updates

=head2 Service Commands 

[SERVICE] :[MESSAGE]

[SERVICE] [ACTION] [ ARGUMENTS .. ]

=head3 Jaiku

=head1 Functions

=head2 new

=cut

my $jobj;

$|=1;

sub new {
	my $class = shift;
	my %args = @_;

	my $self = {};
	bless $self, $class;
	$self->_pre_init;
	return $self;
}

=head2 _pre_init

=cut

sub _pre_init {
	my $self = shift;
	# binmode STDOUT,":utf8";
}

=head2 setup service

=cut 

sub setup_service {
	my ( $self , $args , $opt ) = @_;

	print "Init " , $args->{package_name} , ":\n";
	for my $column ( @{ $args->{require_args} } ) {
		my ($column_name , $column_option )  = each %$column;

		print $column_option->{label} , ":" ;
		my $val = <STDIN>;
		chomp $val;

		$opt->{$column_name} = $val;
	}
}

=head2 init

=cut

sub init {
	my $self = shift;
	$self->print_welcome;

	# init Jaipo here
	$jobj = Jaipo->new;
	$jobj->init( $self );
}

=head2 print_help 

=cut

sub print_help {
	my $self = shift;

	print <<HELP ;

m|mine          to read updates of your own
p|public        to read public messages (from friends,channels)
g|global        to read global messages (from the whole world)

:[message]      update a message to all services.

eval            eval a part of code.

conf edit       edit configuration
conf load       load configuration
conf save       save configuration

use [service trigger]

f create        create a filter
?               print help

[service]  [message]
[service]  :[action]  [arguments]

HELP

}


=head2 print_welcome

=cut

sub print_welcome {
	print "Jaipo Console (version ". $Jaipo::VERSION .")\n";
	print <<'END';
_________________________________________
Type ? for help
Type [service] ? for service plugin help
Type :[message] to send a message

END

}


=head2 process_built_in_commands 

=cut

sub process_built_in_commands {
	my ($self ,$line ) = @_;

	$line =~ s/^://;

	given ($line) {

		# eval code
		# such like:   eval $jobj->_list_trigger;
		when ( m/^eval (.*)$/i ) {
			# eval a code
			my $code = $1;
			eval $1;
		}
	
		when ( m/^conf\s+edit$/i ) { 
			my $editor = $ENV{EDITOR} || 'nano' ;
			my $file = Jaipo->config->app_config_path;
	
			print "Launching editor .. $editor\n";
			qx{$editor $file};
	        }
	
		when ( m/^conf\s+save$/i ) {
			# TODO
			# save configuration 
		}
	
		when ( m/^conf\s+load$/i ) {
			# TODO
			# load configuration
			# when user modify configuration by self, user can reload
			# configuration
		}
	
		when ( m/^list$/i ) {
			$jobj->list_triggers;
		}
	
	
		# built-in commands
		# TODO:
		#
		when (m/^(?:u|use)\s*/i) {
			$line =~ s/;$//;
			my @ops = split /\s+/,$line;
			shift @ops; # shift out use command
			my ( $service_name , $trigger_name ) = @ops;
	
			# init service plugins
			# TODO:
			# check if user specify trigger name
			if ( !$service_name ) {
				$jobj->list_triggers;
			} else {
				$service_name = ucfirst $service_name;
				$trigger_name ||= lc $service_name;
				print "Trying to load $service_name => $trigger_name\n";
				$jobj->runtime_load_service ( $self, $service_name, $trigger_name );
				print "Done\n";
			}
		}
	
	
		# Global Actions
		#
	
		when ( m/^(s|send)/i ) {  
			$jobj->action( "send_msg", $line );
		}
	
		when ( m/^(m|mine)/i ) {  
			$jobj->action( "read_user_timeline", $line );
		}
	
		when ( m/^(p|public)/i ) { 
			$jobj->action( "read_public_timeline", $line );
		}
	
		when ( m/^(g|global)/i ) { 
			$jobj->action( "read_global_timeline", $line );
		}
	
		# XXX: let -p , -m works
		when (m/^-$/) {
			$jobj->cache_clear;
			Jaipo->logger->info("Cache Flushed");
		}
	
		when (m/^mark\s+as\s+read/i) {
			$jobj->cache_clear();
			Jaipo->logger->info("Cache Flushed");
		}
	
	
		# something like filter create /regexp/  :twitter:public
		when (m/^(f|filter)\s/i) {
			my ( $cmd, $action, @params ) = split /\s+/, $line;
		}
	
		when ('?') {
			$self->print_help;
		}
	
		# try to find the trigger , if match then do it
		# or show up command not found
		default {
			# dispatch to service
			my ( $service_tg, $rest_line ) = ( $line =~ m/^(\w+)\s*(.*)/i );
			$jobj->dispatch_to_service( $service_tg, $rest_line );
		}
	}
}

sub parse {
	my ($self,$line) = @_;
	
	$line =~ s/^\s*//g;
	$line =~ s/\s*$//g;
	
	return unless $line;
	
	if( $line =~ m/^:/ ) {
		# do update status message if string start with ":"
		$line =~ s/^://;
		$jobj->action ( "send_msg", $line );
	} else {
		$self->process_built_in_commands( $line );
	}
}


sub auto_update {
	print "Auto-Update Mode\n";
	$SIG{ALRM} = sub { 
		print "Updating ... \r";
		$jobj->action( "read_public_timeline" );
		print "Done" . ' ' x 10 . "\r";
	};
	setitimer(ITIMER_REAL , 1 , 10);
}

sub run {
	my $self = shift;
	my $prompt = "jaipo>  ";
	use utf8;
	# XXX: Term::ReadLine doesnt support UTF-8
	# my $term = new Term::ReadLine; # 'Simple Perl';
	# my $OUT = $term->OUT || \*STDOUT;
	# binmode $OUT,":utf8";
	binmode STDIN,":utf8";
	binmode STDOUT,":utf8";
	# while ( defined ($_ = $term->readline($prompt)) ) {
	while ( 1 ) {
		print $prompt;
		my $line = <STDIN>;
		chomp $line;
		unless( $line ) {
			$self->auto_update;
			<STDIN>;
			$SIG{ALRM} = undef;
			setitimer(ITIMER_REAL , 0 );
		}
		chomp $line if( $line );
		eval( q{ $self->parse ( $line ); } );
		warn $@ if $@;
		# print $OUT $res, "\n" unless $@;
		# $term->addhistory($_) if /\S/;
	}
}

1;
