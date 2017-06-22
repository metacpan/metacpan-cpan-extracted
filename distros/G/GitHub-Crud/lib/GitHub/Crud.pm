#-------------------------------------------------------------------------------
# Create, Read, Update, Delete files on GitHub
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

package GitHub::Crud;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Digest::SHA1 qw(sha1_hex);
use File::Temp qw(tempfile);
use MIME::Base64;

our $VERSION = '2017.615';

my $develop = 0;                                                                # Set to true if developing
my $pat = '40 chars length access token from GitHub';                           # A sample access token that is only used during the tesing of this module

Data::Table::Text::genLValueScalarMethods(
  qw(branch),                                                                   # Optional: branch name (you should create this branch manually first) or omit it for the default branch which is usually 'master'
  qw(gitFile),                                                                  # REQUIRED: File name on GitHub - this name can contain /
  qw(personalAccessToken),                                                      # REQUIRED: a personal access token with scope "public_repo" as generated on page: https://github.com/settings/tokens
  qw(repository),                                                               # REQUIRED: the name of your repository - you should create this repository first, manually
  qw(userid),                                                                   # REQUIRED: your user id on GitHub
  qw(onFail),                                                                   # Optional: a 𝘀𝘂𝗯 that will be called if a failure is detected, otherwise I will confess
 );

sub GitHub::Crud::Response::new($$)                                             # Execute a request against GitHub and decode the response
 {use Carp;
  use Data::Dump qw(dump);
  use Data::Table::Text qw(:all);
  use JSON;
  use MIME::Base64;

  my ($gitHub, $request) = @_;

  my $R = bless {command=>$request}, "GitHub::Crud::Response";                  # Construct the response
  my $r = xxx $request, qr(HTTP);

  $r =~ s/\r//gs;                                                               # Internet line ends

  my ($http, @r) = split /\n/, $r;
  while(@r > 2 and $http =~ "HTTP/1.1" and $http =~ /100/)                      # Continue messages
   {shift @r; $http = shift @r;
   }

  if ($http =~ "HTTP/1.1" and $http =~ /200|201|404/)
   {my $ps = 0;                                                                 # Parse the response
    my @data;
    my %can;

    for(@r)
     {if ($ps == 0)
       {if (length == 0)
         {$ps = 1;
         }
        else
         {my ($name, $content) = split /\s*:\s*/, $_, 2;                        # Parse each header
          $name =~ s/-/_/gs;                                                    # Translate - in names to _
          if ($R->can($name))
           {$R->$name = $content;
           }
          else {$can{$name}++}                                                  # Write list of new methods required
         }
       }
      else
       {push @data, $_;
       }
     }
    if (keys %can and $develop)                                                 # List of new methods required
     {say STDERR "qw($_)," for(sort keys %can);
     }

    if (@data)                                                                  # Save any data
     {my $j = join ' ', @data;
      my $p = $R->data = bless decode_json($j), "GitHub::Crud::Response::Data";
      if (my $c = $p->content)
       {my $d = $R->content = decode_base64($c);                                # Decode the data
       }
     }

    return $R
   }
  else
   {if (my $f = $gitHub->onFail)
     {return $gitHub->$f($r);
     }
    confess "Unexpected response from GitHub:\n", $r;
   }
 }

if (1)
 {package GitHub::Crud::Response;

  Data::Table::Text::genLValueScalarMethods(
qw(Accept_Ranges),
qw(Access_Control_Allow_Origin),
qw(Access_Control_Expose_Headers),
qw(Cache_Control),
qw(Connection),
qw(Content_Length),
qw(content),                                                                    # Output: the actual content of the file from GitHub
qw(Content_Security_Policy),
qw(Content_Type),
qw(data),                                                                       # Output: the data received from GitHub, normally in json format
qw(Date),
qw(ETag),
qw(Expires),
qw(Last_Modified),
qw(Server),
qw(Source_Age),
qw(Status),
qw(Strict_Transport_Security),
qw(Vary),
qw(Via),
qw(X_Accepted_OAuth_Scopes),
qw(X_Cache),
qw(X_Cache_Hits),
qw(X_Content_Type),
qw(X_Content_Type_Options),
qw(X_Fastly_Request_ID),
qw(X_Frame_Options),
qw(X_Geo_Block_List),
qw(X_GitHub_Media_Type),
qw(X_GitHub_Request_Id),
qw(X_OAuth_Scopes),
qw(X_RateLimit_Limit),
qw(X_RateLimit_Remaining),
qw(X_RateLimit_Reset),
qw(X_Served_By),
qw(X_Timer),
qw(X_XSS_Protection),
  );
 }

if (1)
 {package GitHub::Crud::Response::Data;                                         # Response JSON from GitHubExecute a request against GitHub and decode the response

  Data::Table::Text::genLValueScalarMethods(
qw(command),                                                                    # Command used to construct this response
qw(content),
qw(documentation_url),
qw(download_url),
qw(encoding),
qw(git),
qw(git_url),
qw(html),
qw(html_url),
qw(_links),
qw(message),
qw(name),
qw(path),
qw(self),
qw(sha),
qw(size),
qw(type),
qw(url),
  );
 }

#-------------------------------------------------------------------------------
# Get sha for data - only used for testing at the moment
#-------------------------------------------------------------------------------

sub getSha($)
 {my ($data) = @_;
  my $length = length($data);
  my $blob   = 'blob' . " $length\0" . $data;
  sha1_hex($blob);
 }

if (0)
 {my $sha = getSha("<h1>Hello World</h1>\n");
  my $Sha = "f3e333e80d224c631f2ff51b9b9f7189ad349c15";
  unless($sha eq $Sha)
   {confess "Wrong SHA: $sha".
            "Should be: $Sha";
   }
 }

#-------------------------------------------------------------------------------
# Personal access token string
#-------------------------------------------------------------------------------

sub patKey($$)
 {my ($gitHub, $required) = @_;                                                 ## GitHub, whether the personal access key is required
  my $pat      = $gitHub->personalAccessToken;
  if (!$pat)
   {return '' unless $required;
    confess "Personal access token required with scope \"public_repo\"".
            " as generated on page:\nhttps://github.com/settings/tokens";
   }
  "-H \"Authorization: token $pat\""
 }

#-------------------------------------------------------------------------------
# Ref or branch - usage appears to be inconsistent
#-------------------------------------------------------------------------------

sub refOrBranch($$)
 {my ($gitHub, $ref) = @_;                                                      ## Github, whether to use ref rather than branch
  my $b = $gitHub->branch;
  return "?ref=$b"    if  $ref and $b;
  return "?branch=$b" if !$ref and $b;
  ''
 }

#1 Methods available

sub new                                                                         # Create a new GitHub object

 {my $curl = qx(curl -V);                                                       # Check Curl
  if ($curl =~ /command not found/)
   {confess "Command 𝗰𝘂𝗿𝗹 not found"
   }
  return bless {}
 }

sub readData($)                                                                 # Read data from a file on GitHub
 {my ($gitHub) = @_;                                                            # GitHub object
  my $user = $gitHub->userid;     $user or confess "userid required";
  my $repo = $gitHub->repository; $repo or confess "repository required";
  my $file = $gitHub->gitFile;    $file or confess "gitFile required";
  my $bran = $gitHub->refOrBranch(1);
  my $pat  = $gitHub->patKey(0);

  my $s = filePath
   ("curl -si $pat https://api.github.com/repos", $user, $repo,
     qq(contents), $file.$bran);

  GitHub::Crud::Response::new($gitHub, $s);
 }

if (0)
 {my $g = GitHub::Crud::new();
  $g->userid     = "philiprbrenan";
  $g->repository = "horses";
  $g->gitFile    = "test.html";
  my $r = $g->readData;
  say STDERR "Read:\n", dump($r);
 }

sub writeData($$)                                                               # Write data into a GitHub file, creating the file if it is not there already
 {my ($gitHub, $data) = @_;                                                     # GitHub object, data to be written
  defined($data) or confess "data required";
  my $pat  = $gitHub->patKey(1);
  my $user = $gitHub->userid;     $user or confess "userid required";
  my $repo = $gitHub->repository; $repo or confess "repository required";
  my $file = $gitHub->gitFile;    $file or confess "gitFile required";
  my $bran = $gitHub->refOrBranch(0) || '?';

  my $r    = $gitHub->readData;
  my $sha  = $r->data->sha ? ', "sha": "'. $r->data->sha .'"' : '';
  my $denc = encode_base64($data) =~ s/\n//gsr;

  my (undef, $tmpFile) = tempfile();                                            # Create a temporary file for the data to be written otherwise the command line invocation of 𝗰𝘂𝗿𝗹  might become too long

  writeFile($tmpFile, qq({"message": "", "content": "$denc" $sha}));            # Write encoded content to temporary file

  my $u = filePath
   ("https://api.github.com/repos",
    $user, $repo, qw(contents), $file.$bran.qq( -d @).$tmpFile
   );

  my $s = "curl -si -X PUT $pat $u";                                            # Curl command
  my $w = GitHub::Crud::Response::new($gitHub, $s);                             # Execute command to create response
  unlink $tmpFile;                                                              # Cleanup
  $w                                                                            # Return response
 }

if (0)
 {my $g = GitHub::Crud::new();
  $g->userid     = "philiprbrenan";
  $g->repository = "horses";
  $g->gitFile    = "test4.html";
  $g->personalAccessToken = $pat;
  my $d = dateTimeStamp;
  my $w = $g->writeData("$d\n"x1000);
  say STDERR "Write:\n", dump($w);
 }

sub deleteData($)                                                               # Delete a file already on GitHub
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat  = $gitHub->patKey(1);
  my $user = $gitHub->userid;     $user or confess "userid required";
  my $repo = $gitHub->repository; $repo or confess "repository required";
  my $file = $gitHub->gitFile;    $file or confess "gitFile required";
  my $bran = $gitHub->refOrBranch(0);

  my $r    = $gitHub->readData;
  my $sha  = ' -d \'{"message": "", "sha": "'. $r->data->sha .'"}\'';

  my $u = filePath
   ("https://api.github.com/repos", $user, $repo, qw(contents),
    $file.$bran.$sha);

  my $s = "curl -si -X DELETE $pat $u";
  my $d = GitHub::Crud::Response::new($gitHub, $s);
  $d
 }

if (0)
 {my $g = GitHub::Crud::new();
  $g->userid     = "philiprbrenan";
  $g->repository = "horses";
  $g->gitFile    = "test4.html";
  $g->personalAccessToken = $pat;
  my $d = $g->deleteFile;
  say STDERR "Delete:\n", dump($d);
 }

#-------------------------------------------------------------------------------
# Tests
#-------------------------------------------------------------------------------

if (0 and !caller)
 {my $g = GitHub::Crud::new();
  $g->userid     = "philiprbrenan";
  $g->repository = "horses";
  $g->gitFile    = "testFromAppaApps.html";
  $g->personalAccessToken = $pat;

  my $d = dateTimeStamp."\n";

  say STDERR
     "\n Write : \n\n", dump($g->writeData($d x 1000)),
   "\n\n Read 1: \n\n", dump($g->readData->content),
   "\n\n Delete: \n\n", dump($g->deleteData),
   "\n\n Read 2: \n\n", dump($g->readData);
 }

#-------------------------------------------------------------------------------
# Test
#-------------------------------------------------------------------------------

sub test
 {eval join('', <GitHub::Crud::DATA>) || die $@
 }

test unless caller();

# Documentation
#extractDocumentation unless caller;

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

1;

=pod

=encoding utf-8

=head1 Name

GitHub::Crud - Create, Read, Update, Delete files on GitHub.

=head1 Synopsis

Create, Read, Update, Delete files on GitHub as described at:

  https://developer.github.com/v3/repos/contents/#update-a-file

=head1 Prerequisites

 sudo apt-get install curl

=head1 Example

 use GitHub::Crud;

 {my $g = GitHub::Crud::new();
  $g->userid     = "philiprbrenan";
  $g->repository = "horses";
  $g->gitFile    = "test4.html";
  $g->personalAccessToken = $pat;

  my $d = dateTimeStamp."\n";

  say STDERR
     "\n Write : \n\n", dump($g->writeData($d x 100)),
   "\n\n Read 1: \n\n", dump($g->readData->content),
   "\n\n Delete: \n\n", dump($g->deleteData),
   "\n\n Read 2: \n\n", dump($g->readData);
 }

Creates a file by writing 100 lines of data to it, reads the file to get its
attributes and contents, deletes the file, then tries to read the deleted file.

=head1 Parameters

The following parameters are available:

=head2 branch

Optional: branch name (you should create this branch manually first) or omit it
for the default branch which is usually 'master'

=head2 gitFile

REQUIRED: File name on GitHub - this name can contain /

=head2 personalAccessToken

REQUIRED: a personal access token with scope "public_repo" as generated on
page:

  https://github.com/settings/tokens

You can delete this token on the same page to maintain the security of your
GitHub account.

=head2 repository

REQUIRED: the name of your repository - you should create this repository
first, manually

=head2 userid

REQUIRED: your user id on GitHub

=head2 onFail

Optional: a 𝘀𝘂𝗯 that will be called if a failure is detected, otherwise

 Carp::confess

is called to display an error message

=head1 Methods available

=head2 new()

Create a new GitHub object

=head2 readData($gitHub)

Read data from a file on GitHub

     Parameter  Description
  1  $gitHub    GitHub object

=head2 writeData($gitHub, $data)

Write data into a GitHub file, creating the file if it is not there already

     Parameter  Description
  1  $gitHub    GitHub object
  2  $data      data to be written

=head2 deleteData($gitHub)

Delete a file already on GitHub

     Parameter  Description
  1  $gitHub    GitHub object

=head1 Index

L</deleteData($gitHub)>
L</new()>
L</readData($gitHub)>
L</writeData($gitHub, $data)>

=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut

__DATA__
use Test::More tests => 1;

ok 1;
