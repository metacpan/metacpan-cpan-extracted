package HtDig::Site;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @accepted_fuzzy_types);
use File::stat;
use File::Copy;
use File::Spec;
use Date::Manip;
use Net::SMTP;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(time_dig);

$VERSION = '1.02';



###
#This array defines the known fuzzy index types that can be
# created by htfuzzy
###
@accepted_fuzzy_types = qw/soundex metaphones endings synonyms/;
sub fuzzy_types {@accepted_fuzzy_types}

##
#Conf metadata is used to validate input and pre-existing values
# when importing conf files.  It is based on the htdig documentation
# and its interpretation of what each config setting represents.
#For more information on htdig config file data types, see
# http://www.htdig.org/cf_types.html
#
#P.S.: It can also be used to get a list of stock settings
##
my $conf_metadata = {
		database_dir => 'STRING',
		word_db => 'STRING',
		start_url => 'STRING LIST',
		limit_urls_to => 'STRING LIST',
		exclude_urls => 'STRING LIST',
		maintainer => 'STRING',
		max_head_length => 'NUMBER',
		max_doc_size => 'NUMBER',
		no_excerpt_show_top => 'BOOLEAN',
		search_algorithm => 'STRING LIST',
		template_map => 'STRING LIST',
		template_name => 'STRING',
		next_page_text => 'STRING',
		no_next_page_text => 'STRING',
		prev_page_text => 'STRING',
		no_prev_page_text => 'STRING',
		page_number_text => 'STRING',
		no_page_number_text => 'STRING',
		configdig_notify => 'STRING LIST',
		bad_extensions => 'STRING LIST',
	       };

##
#Constructor for Site object
##
sub new {
  my ($class, %attribs) = @_;
  my $conf_path = $attribs{conf_path};

  #Autocreate allows us to create a conf that doesn't
  # already exist.
  if ($attribs{auto_create}) {
    unless (-f $conf_path) {
      #I avoid using "touch" on the file to ensure cross-platform
      # compatibility, opting instead to just open it for writing.
      open(TMP,">$conf_path");
      close(TMP);
    }
  }

  my $st = stat($conf_path);
  if (!$st) {
    die "Couldn't access file $conf_path: $!\n(try using parameter value auto_create=>1 if you want this file to be created)\n";
  }
  my $mtime = $st->mtime;

  #If we weren't provided with a Config object ref, we create one
  if($attribs{config} && ref($attribs{config}) ne "HtDig::Config") {
#    print STDERR $attribs{config} . "\n";
    $attribs{config} = new HtDig::Config($attribs{config});
  }

  my $self = {
	      site_name => $attribs{site_name},
	      trace_lvl => $attribs{trace_lvl},
	      conf_path => $conf_path,
	      mtime => $mtime,  #For avoiding concurrency problems
	      settings => {},
	      auto_create => $attribs{auto_create},
	      config => $attribs{config},
	     };
  bless $self, $class;


  $self->_get_settings($conf_path) or die "Couldn't interpret conf file $conf_path";
  return $self;
}

##
#Retrieve or modify a configuration setting
##
sub setting {
  my ($self, $setting, $value) = @_;
  #Check to see if they provided a new value for this setting
  if (defined($value) and $value eq "") {
    $self->_trace("Deleting value for $setting",1);
    return delete($self->{settings}->{$setting});    
  }
  elsif ($value) {
    #Get the cleaned up value from validation routine
    my $validated = $self->_validate_setting(type=>$conf_metadata->{$setting}, value=>$value);
    #Validation returns undef on failure
    if ($validated) {
      #Set value and return it
      $self->{settings}->{$setting} = $validated;
      return $validated;
    }
    else {
      #Return undef to indicate failure
      $self->_trace("Value provided for $setting failed validation",1);
      return undef;
    }
  }
  #They didn't assign a value so just return the current value
  else {
    return $self->_validate_setting(type=>$conf_metadata->{$setting}, value=>$self->{settings}->{$setting});
  }
}

sub _get_settings {
  my ($self, $conf_path) = @_;
  my $settings = {};
  open(CONF, $conf_path) or die "Couldn't open configuration file at $conf_path for reading: $!";
  my $more = 1;
  while($more) {
    my ($pretext, $key, $value);
    #We throw away the pretext when reading the conf file, because
    # it's preserved when writing the file later
    ($pretext, $key, $value, $more) = $self->_get_next_setting(*CONF);
    $settings->{$key} = $self->_validate_setting(value=>$value, type=>$conf_metadata->{$key});
  }
  $self->{settings} = $settings;
  return 1;
}

sub _get_next_setting {
  my ($self, $fh) = @_;
  my ($line, $setting, $pretext, $key, $value);
  my $setting_found = 0;
  until ($setting_found) {
    $line = <$fh>;
    return($pretext, undef, undef, 0) if !$line;
    if ($line =~ /^#/) {
	$pretext .= $line;
#      print "Pretext: $pretext\n";
	next;
    };
    ($key, $value) = $line =~ /^\s*(\w+)\s*:\s*(.+)/;
    if (!$value) {
      $pretext .= $line;
      next;
    }
    while ($value =~ /\\$/) {
      defined(my $next_line = <$fh>) or last;
      $value .= $next_line;
    }
    $setting_found = 1;
  }
  #print "Pretext: $pretext\n";
  
  $value =~ s/\s+$//;
  if ($key) {
    $self->_trace("Value for $key extracted:\n$value\n",3);
    #Use the internal validation routine to get the right data format
    $value = $self->_validate_setting(value=>$value, type=>$conf_metadata->{$key});
    if (!$value) {
      $self->_trace("Using null value for setting $key.  This could be the result of a badly formatted conf file being imported for the first time, or it might just be an empty setting.",1);
    }
  }
  #print "returning $pretext\n";
  return ($pretext, $key, $value, 1);  
}

##
#Reload the configuration file
# Useful if someone's modified it since first load
##
sub refresh {
  my ($self) = @_;
  $self->{settings} = _get_settings($self->{conf_path});
  my $st = stat($self->{conf_path});
  $self->{mtime} = $st->mtime;
}

sub save {
  my ($self, %attribs) = @_;
  my ($save_path, $tmp_path);
  #Allow saving to a different file name
  $save_path = $attribs{save_to} ? $attribs{save_to} : $self->{conf_path};
  $tmp_path = $save_path . ".bak";

  my $st = stat($self->{conf_path});
  if ($st->mtime != $self->{mtime}) {
    $self->_trace("Configuration was modified by another process, cannot update without refresh.");
    $self->{errstr} = "Configuration was modified by another process, cannot update without refresh.";
    return 0;
  }
  
  #Create a backup/temp copy of the file
  if (!copy($self->{conf_path}, "$tmp_path")) {
    $self->{errstr} = "Couldn't backup original configuration file to $tmp_path: $!";
    return 0;
  }
  #Open the tmp_path file for reading
  if (!open(ORIG,$tmp_path)) {
    $self->{errstr} = "Couldn't open temp file at " . $self->{conf_path} . " for reading: $!";
    return 0;
  }
  #Open the save_path file for saving
  if (!open(NEW, ">$save_path")) {
    $self->{errstr} =  "Couldn't open configuration file at " . $save_path .  " for writing: $!";
    return 0;
  }

  my (@saved);
  my $more = 1;
#  print NEW "#This file was generated by ConfigDig\n\n";
  while ($more) {
    my ($pretext, $key, $value);
    ($pretext, $key, $value, $more) = $self->_get_next_setting(*ORIG);
    print NEW $pretext unless $attribs{no_preserve};
    if ($self->setting($key)) {
      print NEW "$key: " . $self->_setting2string($self->setting($key)) . "\n";
      push(@saved, $key);
    }
    else {
#      print "$key: " . $self->setting2string($value;
    }
     #$self->_trace("Setting value for $key to:\n$string_setting",3);
  }

  #Finish up with settings that didn't already exist in the file
  for my $key (keys %{$self->{settings}}) {
    if ($key and !grep(/^$key$/, @saved)) {
      print NEW "$key: " . $self->_setting2string($self->setting($key)) . "\n";
    }
  }

  #Close the filehandles
  close(NEW);
  close(ORIG);

  #After the update, we renew the timestamp
  $st = stat($self->{conf_path});
  $self->{mtime} = $st->mtime;
  return 1;
}

##
#Recursive convenience function for timed "at" jobs
##
sub time_dig {
  use HtDig::Config;
  my ($htdig_conf, $site_name, $notify) = @_;
  my $htdig = new HtDig::Config(conf_path=>$htdig_conf);
  my $site = $htdig->get_site($site_name);
  if(my $PID = $site->dig(notify=>$notify)) {
    print "Site dig successfully started. PID: $PID\n";
  }
  else {
    print "Couldn't initiate dig: " . $site->errstr;
  }
}

##
#Crawl the site(s)
##
sub dig {
  #Watch out:
  # this func returns the PID of the rundig process on success
  # unless you've requested a timed dig, where you'll get the "at"
  # queue job id.
  # Any case returns undef on internal error

  my ($self, %attribs) = @_;

    my $options .= " -c " . $self->{conf_path};
    #Currently the only options supported are "verbosity" and "notify"
    #Others should be added soon
    $options .= $attribs{verbose} ? " -" . ("v" x $attribs{verbose}) : "";


  #Figure out all the necessary details for running the dig
  my $site_name = $self->{site_name};
  my $conf_path = $self->{conf_path};
  my $index_type = $attribs{type};
  my $notify = $attribs{notify};
  my $log_file = $site_name . "_dig_" . ParseDate("now");
  $log_file =~ s/\:/\_/g;
  my $htdig_path = $self->{config}->{htdig_base_path} . "/bin/rundig";
  my $log_file = File::Spec->catfile($self->{config}->{configdig_log_path},$log_file); 

  my $system_cmd = "$htdig_path -c $conf_path $options >> $log_file";


  #If immediate dig was requested, we fork, if not, we schedule for
  # later

  if ($attribs{at}) {
    my ($job_id, $result);

    my $trace_log = File::Spec->catfile($self->{config}->{configdig_log_path},"configdig_at_log");
    open(LOG, ">>$trace_log");
    my $at_time = $attribs{"at"};

    #We must schedule an "at" job
    #For simplicity, I assume that if you aren't mswin32
    # then you have Unix "at".  I know this will cause problems,
    # but this seems the best way to start off, since I'm not
    # familiar with scheduling programs on systems other than Linux and NT
    if ($^O =~ /mswin32/i) {
      #Use NT's "at" command, win95/98 can't do this
      #but, then again, I don't think they can run ht://Dig, anyway
      $self->{errstr} = "Scheduled digs are not yet implemented on $^O operating system\n";
      return undef;
    }
    else {
      #I'm not sure how better to pick up custom library directories, so
      # I'm only handling one at this time.  If you haven't specified a custom
      # library, then this should be harmless...
      #This seems easier than getting the entire @INC array and rebuilding it
      # explicitly with -I parameters!
      my $custom_lib = $INC[0];
      my $at_cmd =  qq|perl -I$custom_lib -MHtDig::Site -e "time_dig('| . $self->{config}->{path} . qq|','| . $self->{site_name} . qq|','$notify')"|;
      $result = `$at_cmd | at $at_time 2>&1`;
      $self->_trace("Piping command to at:\n$at_cmd | at $at_time",2);
      ($job_id) = $result =~ /job (\d+)/;
      $self->_trace("Successfully piped system command to 'at':\nResult: $result");
    }

    if ($job_id) {
      #Success! Return job id we parsed from return value
      return $job_id;
    }
    else {
      #Prettify the error returned from "at" and indicate error condition
      $result =~ s/\n/. /g;
      $self->{errstr} = "Error scheduling \"at\" job: $result";
      return undef;
    }
  }
  else {
    #Fork before we start the process so we are "non-blocking"
    if (my $kid = fork) {
      #I'm the parent
      return $kid;
    }
    elsif (!defined $kid) {
      $self->{errstr} = "Couldn't spawn dig process: $!";
      return undef;
    }

    #From this point onward, we are the forked "child" and are not
    # part of the CGI process that spawned us.

    #These are filehandles for the CGI.  We don't want to tamper with
    # them accidentally, so we close them.
    #(Comment these out if you're doing debugging, and your error log should
    # display the trace messages)
    close STDERR;
    close STDIN;
    close STDOUT;

    my $retval = system("$system_cmd");

    #If notify flag is set, we attempt to notify the admins
    if ($attribs{notify}) {
      $self->_notify_admins("Site indexing run for ht://Dig configuration named " . $self->{site_name} . " has completed.\nRundig exit code: $retval\nLog saved at $log_file\n\nThis message was autogenerated by the ConfigDig configuration system.");
    }


    $self->_trace("htdig returned exit code $retval when running dig\n",1); 
    #We exit because we are the child process
    exit;
  }
}

##
#Generate fuzzy indexes
##
sub generate_fuzzy_index {
  #Watch out:
  # this func returns the PID of the htfuzzy process on success
  # or undef on internal error
  #

  my ($self, %attribs) = @_;
  my $idx_type = $attribs{type};

  #Check to make sure we have a valid Config reference
  if (!$self->{config}) {
    $self->{errstr} = "To generate fuzzy indexes, you must access the Site object via the Config object's get_site() method.";
    return undef;
  }

  #Generate the verbosity flag, if requested
  my $options .= $attribs{verbose} ? " -" . ("v" x $attribs{verbose}) : "";

  #Check the accepted types to make sure the requested type is valid
  if (!grep(/^$idx_type$/, @accepted_fuzzy_types)) {
    $self->_trace("Unsupported fuzzy index of type $idx_type was requested.  Only " . join(", ", @accepted_fuzzy_types) . " are supported.",1);
    $self->{errstr} = "Unsupported fuzzy index of type $idx_type was requested.  Only " . join(", ", @accepted_fuzzy_types) . " are supported.";
    return undef;
  }
  
  #Fork before we start the process so we are "non-blocking"
  if (my $kid = fork) {
    #I'm the parent
    return $kid;
  }
  elsif (!defined $kid) {
    $self->{errstr} = "Couldn't spawn index creation process: $!";
    return undef;
  }

  #Generate the index using htfuzzy at the appropriate location
  close STDERR;
  close STDIN;
  close STDOUT;
  my $site_name = $self->{site_name};
  my $conf_path = $self->{conf_path};
  my $index_type = $attribs{type};
  my $log_file = $site_name . "_" . $index_type . "_" . ParseDate("now");
  $log_file =~ s/\:/\_/g;
  my $htfuzzy_path = $self->{config}->{htdig_base_path} . "/bin/htfuzzy";
  my $log_file = File::Spec->catfile($self->{config}->{configdig_log_path},$log_file); 
  my $system_cmd = "$htfuzzy_path -c $conf_path $options $index_type >> $log_file";

#  $self->_trace($system_cmd,1);
  my $retval = system("$system_cmd");
  $self->_trace("htfuzzy returned exit code $retval when generating $idx_type\n",1); 
  #We exit because we are the child process
  exit;
}

##
#Merge database functionality
##
sub merge {
  #Watch out:
  # this func returns the PID of the htmerge process on success
  # or undef on internal error
  #

  my ($self, %attribs) = @_;

  #Check to make sure we have a valid Config reference
  if (!$self->{config}) {
    $self->{errstr} = "To generate fuzzy indexes, you must access the Site object via the Config object's get_site() method.";
    return undef;
  }

  #Generate the verbosity flag, if requested
  my $options .= $attribs{verbose} ? " -" . ("v" x $attribs{verbose}) : "";

  #Check to see if we're merging another database into this one
  if ($attribs{merge_site}) {
    my $msite = $self->{config}->get_site($attribs{merge_site});
    $options .= " -m " . $msite->{conf_path};
  }
  
  #Check to see if they requested alternate work files, no words db merge, or
  # no document db merge
  $options .= " -a" if $attribs{work_files};
  $options .= " -w" if $attribs{not_words};
  $options .= " -d" if $attribs{not_documents};
  
  #Fork before we start the process so we are "non-blocking"
  if (my $kid = fork) {
    #I'm the parent
    return $kid;
  }
  elsif (!defined $kid) {
    $self->{errstr} = "Couldn't spawn merge process: $!";
    return undef;
  }

  #Merge using htmerge at the appropriate location
  #Close the filehandles the parent might be using
  close STDERR;
  close STDIN;
  close STDOUT;

  #Set up the system call
  my $site_name = $self->{site_name};
  my $conf_path = $self->{conf_path};
  my $index_type = $attribs{type};
  my $log_file = $site_name . "_merge_" . ParseDate("now");
  $log_file =~ s/\:/\_/g;
  my $htmerge_path = $self->{config}->{htdig_base_path} . "/bin/htmerge";
  my $log_file = File::Spec->catfile($self->{config}->{configdig_log_path},$log_file); 
  my $system_cmd = "$htmerge_path -c $conf_path $options >> $log_file";

  $self->_trace($system_cmd,1);
  my $retval = system("$system_cmd");
  $self->_trace("htmerge returned exit code $retval when performing merge\n",1); 

  #Exit because we are the child process
  exit;
}

##
#Error handling, debugging, tracing
##
sub errstr {
  my ($self) = @_;
  return $self->{errstr};
}

sub _notify_admins {
  my ($self, $msg) = @_;

  #Check to see if extra notification recipients have been defined
  my @admins = @{$self->setting("configdig_notify")};
  push(@admins, $self->setting("maintainer"));
  if (!@admins) {
    $self->{errstr} = "Notification requested, but no administrators or maintainer configured.";
    return 0;
  }

  my $mailhost = $self->{config}->{mailhost} || 'localhost';

  print "Mailhost is $mailhost\n";
  print "Admins are " . join(", ", @admins) . "\n";


  my $smtp = new Net::SMTP($mailhost, Debug=>0);
  $smtp->mail("ConfigDig\@localhost");
  $smtp->to(@admins);
  $smtp->data();
  $smtp->datasend($msg);
  $smtp->datasend("\n");
  $smtp->dataend();
  $smtp->quit;

  return 1;
}

sub _trace {
  my($self, $msg, $trace_lvl) = @_;
  return if !$self->{trace_lvl};
  if (!$trace_lvl or ($self->{trace_lvl} ge $trace_lvl)) {
    if (ref($self->{trace_cb}) eq "CODE") {
      &{$self->{trace_ob}}($msg);
    }
    elsif ($self->{trace_cb}) {
      print {$self->{trace_cb}} "TRACE: " . $msg . "\n";
    }
    else {
      print STDERR "TRACE: " . $msg . "\n";
    }
  }
}

sub datatypes {return $conf_metadata;}

sub _setting2string {
  my ($self, $setting) = @_;
  my $reftype = ref($setting);
  if ($reftype eq "ARRAY") {
    return join(" ", @{$setting});
  }
  else {
    return $setting;
  }
}

sub _validate_setting {
  #Returns cleaned-up setting value on success, and undef on failure
  my ($self, %attribs) = @_;
  if ($attribs{type} eq 'STRING' or !$attribs{type}) {
    $attribs{value} =~ s/[^\\]\n/\\\n/g; #end lines with \ to indicate continuation
    return $attribs{value};
  }
  elsif ($attribs{type} eq 'STRING LIST') {
    if (ref($attribs{value}) eq 'ARRAY') {
      return $attribs{value};
    }
    elsif (my @vals = split(/\s/, $attribs{value})) {
      return \@vals;
    }
    else {
      return undef;
    }
  }
  elsif ($attribs{type} eq 'NUMBER') {
    if ($attribs{value} =~ /^\d*$/) {
      return $attribs{value};
    }
    else {
      return undef;
    }
  }
  elsif ($attribs{type} eq 'BOOLEAN') {
    if ($attribs{value} =~ /0|false|f|no/i) {
      return 0;
    }
    elsif ($attribs{value} =~ /1|true|t|yes/i) {
      return 1;
    }
    else {
      return undef;
    }
  }
  else {
    $self->{errstr} = "Datatype $attribs{type} cannot be validated.";
    $self->_trace("Datatype $attribs{type} cannot be validated.");
    return undef;
  }
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

HtDig::Site - Perl extension for managing a single ht://Dig configuration

=head1 SYNOPSIS

  use HtDig::Site;
  $site = new HtDig::Site(conf_path=>"/opt/www/conf/htdig.conf");
  $site->setting("maintainer", "jtillman@bigfoot.com");
  $site->save();
  $site->dig(verbose=>3);

=head1 DESCRIPTION

HtDig::Site provides an object for manipulating configuration files for ht://Dig, a popular open source content indexing and searching system.  The Site object allows you to open a configuration file, modify settings in it, including custom settings that don't directly relate to ht://Dig executibles, and also allows you to perform database operations such as site index runs, database merges, and fuzzy index creation.

=head1 METHODS

=over 4

=item *new

  $site = new HtDig::Site(conf_path=>"/opt/www/conf/htdig.conf", trace_lvl=>1, site_name=>"Default");

new creates a new Site object and returns it.  The only required parameter is conf_path.  auto_create allows the object to create the file specified in conf_path if it doesn't already exist.  trace_lvl is mainly for debugging problems, and site_name is really only meant to be used by the Config object, which provides you with named access to registered configuration files.  Wouldn't you rather be able to use the name "My Site", instead of "/opt/www/conf/htdig.conf"?  That's what Config does for you.  But there's nothing stopping you from naming a Site object yourself when you create it explicitly; the name just won't persist beyond the current session.


=item *setting

  $site->setting("exclude_urls", ["http://localhost/cgi-bin", "http://localhost/images"]);
  @exlude_urls = $site->setting("exclude_urls");

Allows you to modify or retrieve a setting in the configuration file.  You must save the file before it will be persisted.

As illustrated in the example, if the datatype of the setting you are attempting to modify is a "string list", you can pass in an array reference.  Otherwise, you can pass in a space separated list of values, and the Site object will convert it to an array reference by splitting on the white space.  The array reference is for internal representation only, and will be converted to a space separated list when the config file is written to disk.

=item *refresh

  $site->refresh();

When a configuration file is first loaded from disk (or saved for the first time), its modification time is stored in memory and will be compared when the save method is called.  If you suspect someone might have touched the file on disk and wish to sync up with its current version, you can use the refresh method.  Any changes since the last save will be lost.

=item *save

  $site->save();
  $site->save(save_to=>'/opt/www/conf/htdig2.conf');

Saves the in-memory settings to disk.  If the optional save_to parameter is provided, the file is written to that path, otherwise, it's written to the original conf_path that was provided when the object was created.

=item *dig

  $site->dig();

Initiates a site indexing run.

=item *generate_fuzzy_index

  $site->generate_fuzzy_index();

Generates a fuzzy_index of the type specified in the parameter type.


=item *merge

  $site->merge(merge_site=>"/opt/www/conf/othersite.conf",not_words=>1, not_documents=>0, work_files=>1);

Performs a merge using htmerge, merging the configuration file specified
in merge_site into the current Site's database.  not_words, not_documents,
and work_files correspond to the htmerge command line options C<-w>,
C<-d>, and C<-a>, respectively.

=item *datatypes

  my @stock_settings = keys %{$site->datatypes};

Returns a hash that describes ht://Dig configuration file setting datatypes.  These are documented at http://www.htdig.org/confindex.html.  The example uses the hash to get a list of stock settings that htdig recognizes.

The hash structure looks something like this:

  {
   setting_name => 'DATATYPE'
  }

...where setting_name is the name of the configuration file setting, such as "maintainer", and DATATYPE is the documented datatype of the setting.  There are four currently documented datatypes: string, string list, number, and boolean.

This feature is probably not very useful for the perl scripter using the Site object, but it is provided just in case some input validation needs to be done, or some options need to be presented to the user.  It's a good way to present a list of the stock settings that can appear in a configuration file.

=item *errstr

  print $site->errstr . "\n";

Returns the most recently generated error.  The Site object doesn't bother with error numbers, since they would be arbitrary and difficult to track.  This may change if demand is high enough for error numbers.

=back

=head1 KNOWN ISSUES

=over 4

=item * Timed digs are broken.  Needs work.

=back

=head1 AUTHOR

James Tillman <jtillman@bigfoot.com>
CPAN PAUSE ID: jtillman

=head1 SEE ALSO

HtDig::Config.

perl(1).

=cut
