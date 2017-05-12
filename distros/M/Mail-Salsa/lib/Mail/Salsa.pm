#
# Mail/Salsa.pm
# Last Modification: Fri May 28 19:22:47 WEST 2010
#
# Copyright (c) 2010 Henrique Dias <henrique.ribeiro.dias@gmail.com>.
# All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa;

use 5.008000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Mail::Salsa::Config;
use Mail::Salsa::Utils;
use Mail::Salsa::Logs qw(logs);
use MIME::Explode;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.15';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {
		headers     => {},
		message     => undef,
		action      => "",
		list        => "",
		list_dir    => "",
		logs_dir    => "",
		tmp_dir     => "/tmp",
		archive_dir => "",
		queue_dir   => "",
		smtp_server => [],
		from        => "",
		config      => {},
		@_
	};
	bless ($self, $class);
	my $action = ucfirst(lc($self->{'action'}));
	$action or return(undef);
	delete($self->{'action'});

	my $fh = $self->{'filehandle'};
	my $line_from = <$fh>;
	my ($from) = ($line_from =~ /^From +([^ ]+) +/);
	$from or return(undef);
	$self->{'from'} = lc($from);
	$self->parse_stream();
	delete($self->{'filehandle'});
	TEST: {
		unless($action eq "Admin") {
			if(-e (my $cf = Mail::Salsa::Utils::file_path($self->{'list'}, $self->{'list_dir'}, "configuration.txt"))) {
				$self->{'config'} = Mail::Salsa::Config::get_config(
					file     => $cf,
					defaults => {
						'title'            => "",
						'prefix'           => "",
						'subscribe'        => "y",
						'unsubscribe'      => "y",
						'max_message_size' => 0,
						'stamp_life'       => "1m",
						'archive'          => "n",
						'header'           => "n",
						'footer'           => "n",
						'language'         => "en",
						'localnet'         => [],
					},
				);
			} else {
				my ($name, $domain) = split(/\@/, $self->{'list'});
				Mail::Salsa::Utils::tplsendmail(
					smtp_server => $self->{'smtp_server'},
					label       => "LIST_NOT_ACTIVE",
					lang        => $self->{'config'}->{'language'},
					vars        => {
						master => "salsa-master\@$domain",
						from   => "$name\-owner\@$domain",
						to     => $self->{'from'},
						list   => $self->{'list'},
					}
				);
				last TEST;
			}
		}
		eval("use Mail::Salsa::Action::$action;\nMail::Salsa::Action::$action\-\>new(\%\{\$self\});\n");
		$self->logs("[eval] $@", "errors") if($@);
	}
	Mail::Salsa::Utils::clean_dir($self->{'tmp_dir'});
	return($self);
}

sub parse_stream {
	my $self = shift;

	my $id = (my $tmp_dir = "");
	do {
		$id = Mail::Salsa::Utils::generate_id();
		$tmp_dir = join("/", $self->{'tmp_dir'}, $id);
	} until(!(-d $tmp_dir));

	$self->{'tmp_dir'} = $tmp_dir;
	my $filename = ($self->{'message'} = join("/", $tmp_dir, "$id\.msg"));
	my $explode = MIME::Explode->new(
		output_dir     => $tmp_dir,
		mkdir          => 0700,
		decode_subject => 1,
		content_types  => ["text/plain"],
		types_action   => "include"
	);
	open(OUTPUT, ">", $filename) or die("Couldn't open $filename for writing: $!\n");
	eval {
		$self->{'headers'} = $explode->parse($self->{'filehandle'}, \*OUTPUT);
	};
	$self->logs("[eval] $@", "errors") if($@);
	close(OUTPUT);
	return();
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa - An easy to use perl mailing list manager module.

=head1 SYNOPSIS

  use Mail::Salsa;

  my $me = Mail::Salsa->new(
    action      => "post",
    list        => "test\@perl.org",
    list_dir    => "/usr/local/salsa/lists",
    logs_dir    => "/usr/local/salsa/logs",
    archive_dir => "/usr/local/salsa/archives",
    queue_dir   => "/usr/local/salsa/mqueue",
    tmp_dir     => "/tmp",
    filehandle  => \*STDIN
  );

=head1 DESCRIPTION

Mail::Salsa is perl module to create and manage email discussion lists
with an innovative approach in setup and configuration of new lists by the
owners.

=head1 METHODS

=head2 new

This method create a new Mail::Salsa object. The following keys are
available:

=over 9

=item action

The possible actions can be: Post, Subscribe, Unsubscribe, Help and Admin.
Action came from salsa.aliases:

Example: list_at_domain.tld: "|/path/to/cucaracha list@domain.tld Action"

=item list

The address of mailing list (listname@domain.tld).


=item list_dir

The directory where the list live.


=item logs_dir

The directory where the logs are saved.


=item tmp_dir

Temporary directory to parse the stream.


=item archive_dir

Directory path to archive the mailing lists.


=item queue_dir

Directory bla bla


=item filehandle

The reference to STDIN handle.


=item sendmail

Path to sendmail (dafault: /usr/lib/sendmail).


=back


=head1 SEE ALSO

Brent's original paper about Majordomo (Adobe Acrobat file)
http://www.greatcircle.com/majordomo/majordomo.lisa6.pdf

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

Mailing list: salsa-dev@aesbuc.pt

=head1 AUTHOR

Henrique M. Ribeiro Dias, E<lt>henrique.ribeiro.dias@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Henrique M. Ribeiro Dias

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
