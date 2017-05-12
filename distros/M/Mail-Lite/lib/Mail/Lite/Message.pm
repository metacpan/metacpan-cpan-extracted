#
#===============================================================================
#
#         FILE:  Message.pm
#
#  DESCRIPTION:  Mail::Lite::Message -- extra lite message parsing.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.ru>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  11.08.2008 14:25:41 MSD
#     REVISION:  ---
#===============================================================================

package Mail::Lite::Message;

use strict;
use warnings;

use MIME::Words;

use Smart::Comments -ENV;

use Carp;

# Init message object / parse_mail
# IN: message_body
sub new {
    my $self = {};

    bless $self, shift;

    my ($message) = @_;

    @$self{ qw/raw_header body/ } = split (/\r?\n\r?\n/, $message, 2);

    $self->{raw_header} = "\n".$self->{raw_header}."\n";

    unless ( $self->{body} ) {
	die "FATAL: no head/body separator found";
    }

    return $self;
}

sub _received {
    my $self = shift;
    my $value = shift;

    if (    $value =~ m/for <?([-@\w\.]{5,})>?;/is 
	&&  index( $1, '@localhost') < 0 ) {

	push @{ $self->{received_recipients} ||= [] }, $1;
    }
}

#sub _subject {
#    my ($self, $value, $header) = @_;
#
#    $self->{subject} = $header->{subject} = $value;
#}

sub charset {
    my $self = shift;

    $self->{charset} ||= ($self->header( 'content_type' ) && $self->header( 'content_type' ) =~ /charset=\"?([-\w]+)/ios) ? lc $1 : 'us-ascii';
}

sub bound {
    my $self = shift;

    $self->{bound} ||= $1 if $self->header( 'content_type' ) && $self->header( 'content_type' ) =~ m/multipart\/(?:mixed|report);.*?boundary=\"(.+?)\"/ios;
}

sub raw_header {
    my $self = shift;

    $self->{raw_header};
}

sub _check_mime_and_reencode {
    my $value_ref = shift;
    my $origname  = shift;
    if ( $value_ref && $$value_ref && $$value_ref =~ m/\=\?(.+?)\?(.)\?/i ) {
	my @values = MIME::Words::decode_mimewords( $$value_ref,
						    Field => $origname );

	# note -- code page
	$$value_ref = join q{}, map { $_->[0] } @values;
    }
}

sub header {
    my ($self, $field) = @_;

    confess unless $field;
    return $self->{header}{$field} if exists $self->{header}{$field};

    my $nfield = join '-', map { ucfirst } split /_/, $field;

    #$field = 'Received';
    #study($self->{raw_header});

    #my @data = 
    #pos($self->{raw_header}) = 0;
    #my $r = $_header_regexps->{$field} ||= qr/\n$field:\s*((?:.+\n)(?:\s[^\n]+\n)*)/;
    $self->{raw_header} =~ /\n?$nfield:\s*((?:.+\n)(?:\s[^\n]+\n)*)/;

#				    m/
#				    [\t ]*		# skip all spaces
#				    (			# match
#					(?:		# group of
#					    (?!^[\w_\-]+:)  # starting not with word after which ':' is present
#					    .+\n?	# and all the string
#					)+  # few times
#				    )
#				   /mx );

    #use Data::Dumper;
    #warn Dumper \@data;
    #die $self->{raw_header};
    my $value = $1;
    _check_mime_and_reencode( \$value, $nfield );

    return $self->{header}{$field} = ($value || undef);
}

sub headers {
    my $self = shift;

    return $self->{header} if $self->{parsed_headers};

    my %header;
    
    my ($name, $origname, $value);

    $self->{raw_header} =~ s/^(From .*)\n//g;
    #$self->{from} = $1;

    while ( $self->{raw_header} =~ /
				    (^[^:]+?)		# start of field name
				    :			# separator
				    [\t ]*		# skip all spaces
				    (			# match
					(?:		# group of
					    (?!^[\w_\-]+:)  # starting not with word after which ':' is present
					    .+\n?	# and all the string
					)+  # few times
				    )
				   /gmx ) 
    { 
	next unless $2;
#	next if $1 eq 'From' || $1 eq 'Subject';

	($origname, $value) = ($1, $2);

	chomp $value;

	($name = $origname) =~ tr/-A-Z/_a-z/;

	_check_mime_and_reencode( \$value, $origname );

	if ( my $sub = $self->can("_$name") ) {
	    $sub->( $self, $value, \%header );
	    next;
	}

	$header{$name} = exists $header{$name} ? 
	    $header{$name}."\n $value" : $value;
    }

    #$header{subject } = $self->{subject	};
    #$header{from    } = $self->{from	};

    #### %header

    #use Data::Dumper;
    #warn Dumper \%header;

    $self->{parsed_headers} = 1;
    return $self->{header}  = \%header;
}

sub body {
    my $self = shift;

    $self->{body}
}

sub recipients {
    my $self = shift;

    unless ($self->{recipients}) {
	my $header = $self->headers;
	my @to = @{ $self->{received_recipients} || [] };
	push @to, map { /<(.+?)>/ ? $1 : $_ } split /\n\s*/, $self->header('to') if $self->header('to');
	push @to, map { /<(.+?)>/ ? $1 : $_ } split /\n\s*/, $self->header('cc') if $self->header('cc');
	push @to, $1 if	    $self->header('x_rcpt_to') 
			&&  $self->header('x_rcpt_to') =~ m/^<?(.+?)>?$/i;

	my %tmp_to = map { index($_, '@') > 0 ? (lc $_ => 1) : () } @to;
	$self->{recipients} = [ keys %tmp_to ];
    }

    $self->{recipients};
}

# protected

sub slurp_file {
    my ($filename) = @_;
    open( my $fh, '<', $filename) or die "Can't open $filename!\n";
    local($/) = undef;
    my $temp = <$fh>;
    close $fh;
    return $temp;
}

1;
