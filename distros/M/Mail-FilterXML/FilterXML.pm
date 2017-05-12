package Mail::FilterXML;

#(c)2000-2002 Matthew MacKenzie <matt@geek.ca>

use strict;
use vars qw($VERSION);
use Mail::Audit;
use XML::Parser;

$VERSION = '0.3';
sub new {
	my $class = shift;
	my %args = @_; my $self = \%args;
	bless($self, $class);
	return $self;
}

## NOTE - 0.1 is the initial port of this script from being a script to being a module.
## I expect to make it a little bit smarter in future releases.

# Setup the filter structures.  Maybe in future versions these could be hidden in the object.

my @recip_ig = ();
my @subj_ig = ();
my %to_lists = ();
my %from_lists = ();
my %conf = ();
my %action = ();
my %subject_lists = ();
my %current_rule = ();

sub process {
  my $self = shift;
  my $rulesf = $self->{rules_file};
  $self->{message} = new Mail::Audit();
    
  # Parse rules from the XML File..
  
  my $xmlp = new XML::Parser(Handlers => {Start => \&Mail::FilterXML::filtFileStartEl });

  print "Rules file is: $self->{rules}\n";

  $xmlp->parsefile($self->{rules});

  print "Parsed the rules\n";
  
  # Run the filters.
  $self->cleanup_config();
  $self->recipIg();
  $self->subjIg();
  $self->fromLists();
  $self->toLists();
  $self->subjectLists();
  $self->defaultFilter();
}

sub cleanup_config {
  # If the maildir in not defined then set it to the user's home directory
  if ( !defined $conf{maildir} ) {
    $conf{maildir} = "$ENV{HOME}/mail/";
  }
  
  # make sure that maildir ends in a '/'
  if ( $conf{maildir} !~ m|/$| ) {
    $conf{maildir} .= "/";
  }

  # make sure we have a sane logfile
  if ( !defined $conf{logfile} ) {
    $conf{logfile} = $conf{maildir} . "FilterXML.log";
  }
}

sub defaultFilter {
  my $self = shift;
  logger("INBOX", "DEFAULT");
  if ( defined $conf{mailbox} ) {		
    my $mailbox = $conf{maildir} . $conf{mailbox};
    $self->{message}->accept($mailbox);
  }
  else {
    $self->{message}->accept();
  }
}

sub filtFileStartEl {
  my ($p,$el,%att) = @_;
  if ($el =~ /Rule/i) {    
    $current_rule{type} = $att{type};
    $current_rule{content} = $att{content};

    if ($att{type} =~ /from/i) {
      $from_lists{$att{content}} = $att{folder};
    }
    if ($att{type} =~ /to/i) {
      $to_lists{$att{content}} = $att{folder};
    }
    if ($att{type} =~ /subject/i) {
      $subject_lists{$att{content}} = $att{folder};
    }
    if ($att{type} =~ /subj-ignore/i) {
      push(@subj_ig, $att{content});
    }
    if ($att{type} =~ /recip-ignore/i) {
      push(@recip_ig, $att{content});
    }
    if ( defined $att{action_cmd} and defined $att{action_params} ) {
      my $action_string = "$att{type}:$att{content}";
      my $new_action = { action_cmd => $att{action_cmd},
			 action_params => $att{action_params}
		       };
      push(@{$action{$action_string}}, $new_action);
    }
  }
  elsif ( $el =~ /Action/i){
    my $action_string = "$current_rule{type}:$current_rule{content}";
    my $new_action = { action_cmd => $att{action_cmd},
		       action_params => $att{action_params}
		     };
    push(@{$action{$action_string}}, $new_action);    
  }
  elsif ($el =~ /Config/i) {
    foreach my $k (keys %att) {
      $conf{$k} = $att{$k};
    }
  }	
}

sub doAction {
  my $self = shift;
  my $key = shift;
  if ( defined $action{$key} ) {
    # We have an action for the specified rule lets do some checks
    # and run the specified action
    # we can not use Mail::Audit::pipe since that would not allow us to accept the message
    # instead we will make a call to system and check the return code.
    
    my $to = $self->{message}->to;
    my $from = $self->{message}->from;
    my $subject = $self->{message}->subject;

    #
    # $action{$key} is actually an arrayref to anonymous hashes. We need to
    # iterate through all of them for this to work.
    #
    
    my @actions = @{$action{$key}};
    foreach my $task ( @actions ) {
      $task->{action_params} =~ s/#to#/$to/g;
      $task->{action_params} =~ s/#subject#/$subject/g;
      $task->{action_params} =~ s/#from#/$from/g;	   
      
      my $result = 0xffff & system "$task->{action_cmd} $task->{action_params}";
      if ( $result == 0xffff ) {
	$self->logger($task->{action_cmd}, "Action failed with result : $!");
      }
      elsif ( $result > 0x80 ) {
	my $fixed_result = $result >> 8;
	$self->logger($task->{action_cmd}, "Action ran with non-zero exit status : $fixed_result");
      }
      else {
	$self->logger($task->{action_cmd}, "Action");
      }
    }
  }
}

sub toLists {
  my $self = shift;
  foreach my $key (keys %to_lists) {
    if ($self->{message}->to() =~ /$key/i or $self->{message}->cc() =~ /$key/i) {			
      # if we have an action attributed to this rule then lets do it
      $self->doAction("to:$key");		   
      $self->logger($to_lists{$key}, "TO-FILTER");
      $self->{message}->accept("$conf{maildir}".$to_lists{$key});
    }
  }	
}

sub subjectLists {
  my $self = shift;
  foreach my $key (keys %subject_lists) {
    if ($self->{message}->subject() =~ /$key/i) {
      # if we have an action attributed to this rule then lets do it
      $self->doAction("subject:$key");
      # log the results to the log
      $self->logger($subject_lists{$key}, "SUBJECT-FILTER");
      # accept the mail to the specified mail folder
      $self->{message}->accept("$conf{maildir}".$subject_lists{$key});
    }
  }	
}

sub fromLists {
  my $self = shift;
  foreach my $key (keys %from_lists) {
    if ($self->{message}->from() =~ /$key/i) {
      # if we have an action attributed to this rule then lets do it
      $self->doAction("from:$key");
      $self->logger($from_lists{$key}, "FROM-FILTER");
      $self->{message}->accept("$conf{maildir}".$from_lists{$key});
    }
  }
}

sub recipIg {
  my $self = shift;
  foreach my $r (@recip_ig) {
    if ($self->{message}->to() =~ /$r/ or $self->{message}->cc() =~ /$r/) {
      $self->logger("JUNK", "RECIP-IG");
      $self->{message}->accept($conf{maildir}.$conf{junkfolder});
    }
  }
}

sub subjIg {
  my $self = shift;
  foreach my $s (@subj_ig) {
    if ($self->{message}->subject() =~ /$s/) {
      $self->logger("JUNK", "SUBJ-IG");
      $self->{message}->accept($conf{maildir}.$conf{junkfolder});
    }
  }
}

sub logger {
  my ($self, $folder, $filter) = @_;
  open(LOG, ">>$conf{logfile}");
  flock(LOG,2);	
  my $from = $self->{message}->from();
  my $subj = $self->{message}->subject();
  
  chomp($from);
  chomp($subj);
  my $time = scalar(localtime());
  print LOG "$time> $from : $subj -> $folder ($filter)\n";
  close(LOG);
}

1;

__END__

=head1 NAME

Mail::FilterXML - Filter email based on a rules file written in XML.

=head1 SYNOPSIS

  use Mail::FilterXML;
  my $filter = new MailFilter(rules => "/home/matt/mail_rules.xml");
  $filter->process();

=head1 DESCRIPTION

This module builds upon Mail::Audit by Simon Cozens.  Mail::Audit is a module for constructing 
filters, Mail::FilterXML is a filter of sorts.  FilterXML is just made up of some logic for 
processing an email message, and is controlled by the contents of a rules file, so if I wanted to
block a particular sender, I could just add an element to my rules file, like:

<Rule type="from" content="microsoft.com" folder="Trash" action="program" />
See the mail_rules.xml file for an example.

The content attribute can contain perl regexps, such as *\.microsoft\.*$, etceteras.

=head1 FUTURE

I will be adding new "types" of rules, and the ability to reject or altogether ignore messages,
as possible in Mail::Audit.  Any feedback or patches are welcome.

=head1 AUTHOR

Matthew MacKenzie <mattmk@cpan.org>
Eli Ben-Shoshan <eli@benshoshan.com>

=head1 COPYRIGHT

(c)2000-2002 Matthew MacKenzie.  You may use/copy this under the same terms as Perl.

=head1 SEE ALSO

perl(1), Mail::Audit

=cut
