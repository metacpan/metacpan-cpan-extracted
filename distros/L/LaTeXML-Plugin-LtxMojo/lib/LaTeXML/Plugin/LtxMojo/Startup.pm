################ LaTeXML Startup Utilities #####################
package LaTeXML::Plugin::LtxMojo::Startup;
use LaTeXML::Util::ObjectDB;
use LaTeXML::Util::Pathname;
use Data::Dumper;
$Data::Dumper::Terse = 1;          # don't output names where feasible
$Data::Dumper::Indent = 3;         # turn off all pretty print

our $DB_FILE = '.LaTeXML_Startup.cache';
#TODO: Eliminate redundant options

sub new {
  ($class,%opts) = @_;
  $opts{cache}=1 unless defined $opts{cache};
  my $dbfile;
  if ($opts{cache}) {
    my $dbfile = $opts{dbfile}||$DB_FILE;
    if(defined $dbfile && !-f $dbfile){
      if(my $dbdir = pathname_directory($dbfile)){
        pathname_mkdir($dbdir); }}
  }
  my $DB = LaTeXML::Util::ObjectDB->new(dbfile=>$dbfile);
  bless {converters=>{},db=>$DB}, $class;}

###########################################
#### User Management #####
###########################################

sub users {
  my ($self) = @_;
  [ sort map {s/^user://; $_;} grep {/^user:/} grep defined, $self->{db}->getKeys ];
}

sub exists_user {
  my ($self,$user) = @_;
  return defined $self->{db}->lookup("user:$user");
}

sub summary_user {
  my ($self,$user) = @_;
  my $entry = $self->{db}->lookup("user:$user");
  my $summary = '<table class="summary"><tr><th>Property</th><th>Value</th></tr>';
  foreach ($entry->getKeys){
    next if $_ =~ /^pass|key$/; #No pass|key display
    $summary .= "<tr><td>$_</td><td>".Dumper($entry->getValue($_))."</td></tr>\n";
  }
  $summary.="</table>";
  $summary;
}

sub verify_user {
  my ($self,$user,$pass) = @_;
  my $user_entry = $self->{db}->lookup("user:$user");
  if (defined $user_entry && ($pass eq $user_entry->getValue('pass'))) {
    return $user_entry->getValue('role')||1;
  }
  return 0;
}

sub modify_user {
  my ($self,$user,$pass,$role,$default) = @_;
  return "Error: Username can't be empty!\n" unless $user;
  my $user_entry = $self->{db}->lookup("user:$user");
  $role = 'standard' unless $role;
  $default = 'standard' unless $default;
  if (!$user_entry) { #New:
    return "Error: Username and Password can't be empty!\n" unless $user && $pass;
    $self->{db}->register("user:$user",pass=>$pass,role=>$role,default=>$default);
    return "Successfully added user $user with role:$role, default profile:$default!\n";
  } else { #Modify:
    $pass = $user_entry->getValue('pass') unless $pass;
    $role = $user_entry->getValue('role') unless $role;
    $default = $user_entry->getValue('default') unless $default;

    $user_entry->setValues(pass=>$pass,role=>$role,default=>$default);
    return "Successfully modified user $user!\n";
  }
}

sub delete_user {
  my ($self,$user) = @_;
  $self->{db}->unregister("user:$user");
  return "Successfully deleted user $user!\n";
}

sub lookup_user_property {
 my ($self,$user,$prop) = @_;
 my $user_entry = $self->{db}->lookup("user:$user");
 return undef unless defined $user_entry;
 $user_entry->getValue($prop);
}

###########################################
#### Profile Management #####
###########################################


sub modify_profile {
  my($self,$profile,$opts) = @_;
  $self->{db}->register("profile:$profile",%$opts);
}

sub get_profile {
  my ($self,$profile) = @_;
  my $p_entry = $self->{db}->lookup("profile:$profile");
  return $p_entry->as_hashref if defined $p_entry;
  undef;
}

sub profiles {
  my ($self) = @_;
  [ sort map {s/^profile://; $_;} grep {/^profile:/} grep defined, $self->{db}->getKeys ];
}

our $profile_templates = {
                  # Arrayrefs:
                  css => 'arrayref|text',
                  paths => 'arrayref|text',
                  preload => 'arrayref|text',
                  debugs => 'arrayref|text',
                  # Hashrefs:
                  math_formats => 'arrayref|text',
                  authlist => 'hashref|user:text,pass:pass',
                  # Bools:
                  noparse => 'bool',
                  defaultcss => 'bool',
                  local => 'bool',
                  comments => 'bool',
                  icon => 'bool',
                  embed => 'bool',
                  post => 'bool',
                  parallelmath => 'bool',
                  showversion => 'bool',
                  strict => 'bool',
                  includestyles => 'bool',
                  'force_ids' => 'bool',
                  # Text:
                  stylesheet => 'text',
                  inputencoding => 'text',
                  base => 'text',
                  preamble => 'text',
                  documentid => 'text',
                  timeout => 'number',#Do we want this?
                  # Choice:
                  format => 'select|xhtml,html5,html,xml,tex,box', #TODO
                  verbosity => 'select|-5,-1,0,1,5',
                  type => 'select|auto,bib'
};

sub summary_profile {
  my ($self,$profile) = @_;
  my $entry = $self->{db}->lookup("profile:$profile");
  my $summary = '<div class="left-div"><table class="form-table">';
  my @keys = sort $entry->getKeys;
  my $split_when = int(scalar(@keys)/2)+1;
  foreach my $e(@keys) {
    my $t = $profile_templates->{$e};
    $summary.= _inner_handle($e,$t,$entry);
    $split_when--;
    unless ($split_when) {  $summary.='</table></div><div class="right-div"><table class="form-table">';}
  }
  $summary.='</table></div><div class="left-div"><table class="form-table"><tr><td></td><td class="input"><input type="submit" value="Save" /></td></tr>';
  $summary.='</table></div>';
}

sub _inner_handle {
  my ($e,$t,$entry,$flag) = @_;
  my ($type, $spec) = split(/\|/,$t);
  my $summary = q{};
  if ($type eq 'bool') {    $summary .= "<tr><td>$e</td><td class=\"input\"><select name=\"$e\">";
			    if ($entry->getValue($e)||$flag) {
				$summary .= "<option value=\"1\">yes</option><option value=\"0\">no</option>";
			    } else {
				$summary .= "<option value=\"0\">no</option><option value=\"1\">yes</option>";
			    }
			    $summary.="</td></tr>\n"; }
  elsif ($type eq 'text') { $summary .= "<tr><td>$e</td><td class=\"input\"><input name=\"$e\"></td></tr>\n"; }
  elsif ($type eq 'pass') { $summary .= "<tr><td>$e</td><td class=\"input\"><input type=\"password\" name=\"$e\"></td></tr>\n"; }
  elsif ($type eq 'number') { $summary .= "<tr><td>$e</td><td class=\"input\"><input name=\"$e\"></td></tr>\n"; }
  elsif ($type eq 'select') {
      $summary .= "<tr><td>$e</td><td class=\"input\"><select name=\"$e\">";
      my $sel = $entry->getValue($e);
      foreach (split(',',$spec)) {
	  if ($sel ne $_ ) {
	      $summary .= "<option value=\"$_\">$_</option>";
	  } else {
	      $summary .= "<option value=\"$_\" selected>$_</option>";
	  }
      }
      $summary.="</td></tr>\n"; }
  elsif ($type eq 'arrayref') {
      my $current = $entry->getValue($e);
      $summary .= "<tr><td>$e";
      $summary .= "</td><td class=\"input\"><input name=\"$e\" value=\"$_\"></td></tr><tr><td>\n" foreach @$current;
      $summary.= "</td><td></td></tr>";
    }
  elsif ($type eq 'hashref') {
      my $current = $entry->getValue($e);
      $summary .= "<tr><td style=\"border-bottom:2px dashed gray;\">&nbsp;</td><td style=\"border-bottom:2px dashed gray;\">&nbsp;<td/></tr>";
      $summary .= "<tr><td><b>Block $e</b><td></td></tr>";
      foreach (split(/,/,$spec)) {
	  my ($in_e,$in_t) = split(/:/,$_);
	  $summary .= _inner_handle($in_e,$in_t,$entry,$current->{$in_e});
      }
      $summary .= "<tr><td style=\"border-top:2px dashed gray;\">&nbsp;</td><td style=\"border-top:2px dashed gray;\">&nbsp;<td/></tr>";
  }


  $summary;
}

sub template_profile {
  my ($self,$profile,$value) = @_;
  # Add template for adding a new profile
}
###########################################
#### Statistics #####
###########################################


sub status {
  my ($self) = @_;
  #TODO: Provide info on the status of the DB, table of booted converters with their profiles, etc.
  $self->{db}->status;
}

 #TODO: Also provide an interface for examining and changing the options of existing converters

###########################################
#### ObjectDB helpers #####
###########################################
package LaTeXML::Util::ObjectDB::Entry;
sub as_hashref {
  my($self)=@_;
  my $hashref = {};
  foreach (keys %$self) {
    $hashref->{$_} = decodeValue($self->{$_});
  }
  return $hashref;
}

1;

__END__

=pod 

=head1 NAME

C<LaTeXML::Plugin::LtxMojo::Startup> Basic support for user and conversion profile management.

=head1 SYNOPSIS

my $startup = Startup->new();

=head1 DESCRIPTION

=head2 METHODS

=head3 Generics and Defaults

=over 4

=item C<< $DB_FILE >>

Contains the generic default for a Database File to hold the state information of
 converters, users and conversion profiles.

=item C<< $PROFILES >>

Contains the default profiles recognized by the conversion interface.

=item C<< my $startup = Startup->new(%opts); >>

Initializes a new Startup driver and connects to (or creates) its database file.
 The only admissible option is "dbfile=>filepath" used to specify the location and name of the DB object.

=back

=head3 Converter Management

=over 4

=item C<< $startup->boot_profile($profile); >>

Creates a new converter object of the given profile.

=item C<< $startup->boot_custom($opts); >>

Creates a new converter with the given default options

=back

=head3 User Management

=over 4

=item C<< my $users = $startup->users; >>

Fetches all users registered in the DB object, returning an array reference.

=item C<< my $boolean = $startup->exists_user($username); >>

Checks if a given username is registered in the DB object.

=item C<< my $summary_table = $startup->summary_user($username); >>

Provides an HTML summary table with the DB properties for a given username entry.

=item C<< my $boolean = $startup->verify_user($username,$password); >>

Verifies that a username and password pair match a DB entry.

=item C<< my $report_message = $startup->modify_user($user,$pass,$role,$default); >>

Modifies a user entry's password, role and/or default profile selection, returning a string report message.

=item C<< my $report_message = $startup->delete_user($username); >>

Deletes a user entry, returning a string report message.

=item C<< my $property_value = $startup->lookup_user_property($user,$prop_name); >>

Fetches a value of a requested property name for the user entry designated by $username.
Returns undefined if no such property is set.

=back

=head3 Profile Management

=over 4

=item C<< my $profiles = $startup->profiles; >>

Fetches all profiles registered in the DB object, returning an array reference.

=item C<< my $hashref = $startup->get_profile($profilename); >>

Returns a hash reference with all LaTeXML options characteristic to the profile $profilename.

=item C<< my $summary_table = $startup->summary_profile($profilename); >>

Provides an HTML summary table with the DB properties for a given profilename entry.

=item C<< my $report_message = $startup->modify_profile($profilename,$options); >>

Modifies a profile's properties, as given by a hash reference compliant with the properties template,
 returning a string report message.

=item C<< my $report_message = $startup->delete_profile($profilename); >>

Deletes a profile entry, returning a string report message.

=item C<< my $template_html = $startup->template_profile; >>

Returns a template HTML table, which can be used inside a generic HTML form for profile creation.

=back

=head3 Statistics

=over 4

=item C<< my $status_string = $startup->status; >>

Returns the overall statistics of the DB object, as provided by LaTeXML::Util::ObjectDB.

=back

NOTE: The API is still in active development, expect enhancement and possible changes in the interfaces

=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
