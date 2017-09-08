#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Create, Read, Update, Delete files on GitHub
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------
#podDocumentation

package GitHub::Crud;
use v5.16;
our $VERSION = '20170902';
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(dateTimeStamp decodeBase64 decodeJson encodeBase64 filePath genLValueScalarMethods readFile temporaryFile writeFile xxx);
use Digest::SHA1 qw(sha1_hex);

my $url         = "https://api.github.com/repos";                               # Github api url
my $credentials = 'personalAccessToken.data';                                   # This file is not shipped with the distribution as it contains user specific data
my $develop     = -e $credentials;                                              # Set to true if developing

my ($pat, $testUserid, $testRepository, $testUrl, $testSecret) = sub            # A sample access token that is not included in the distribution
 {return (undef) x 5 unless $develop;
  split /\n/, readFile($credentials);
 }->();

#1 Attributes                                                                   # Create a L<new()|/new> object and then set these attributes to specify your request to GitHub

genLValueScalarMethods(qw(branch));                                             # Branch name (you should create this branch first) or omit it for the default branch which is usually 'master'
genLValueScalarMethods(qw(failed));                                             # Defined if the last request to Github failed else B<undef>.
genLValueScalarMethods(qw(fileList));                                           # Reference to an array of files produced by L<list|/list>
genLValueScalarMethods(qw(gitFile));                                            # File name on GitHub - this name can contain '/'
genLValueScalarMethods(qw(gitFolder));                                          # Folder name on GitHub - this name can contain '/'
genLValueScalarMethods(qw(personalAccessToken));                                # A personal access token with scope "public_repo" as generated on page: https://github.com/settings/tokens
genLValueScalarMethods(qw(readData));                                           # Data produced by L<read|/read>
genLValueScalarMethods(qw(repository));                                         # The name of your repository - you should create this repository first
genLValueScalarMethods(qw(response));                                           # A reference to GitHub's response to the latest request
genLValueScalarMethods(qw(secret));                                             # The secret for a web hook
genLValueScalarMethods(qw(url));                                                # The url for a web hook
genLValueScalarMethods(qw(userid));                                             # Your userid on GitHub
genLValueScalarMethods(qw(writeData));                                          # Data to be written by L<write|/write>

# Supporting packages

sub GitHub::Crud::Response::new($$)                                             # Execute a request against GitHub and decode the response
 {my ($gitHub, $request) = @_;

  my $R = bless {command=>$request}, "GitHub::Crud::Response";                  # Construct the response

  my $r = xxx $request, qr(HTTP);

  $r =~ s/\r//gs;                                                               # Internet line ends

  my ($http, @r) = split /\n/, $r;
  while(@r > 2 and $http =~ "HTTP/1.1" and $http =~ /100/)                      # Continue messages
   {shift @r; $http = shift @r;
   }

  if ($http =~ "HTTP/1.1" and $http =~ /200|201|404|422/)
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
      my $p = $R->data = bless decodeJson($j), "GitHub::Crud::Response::Data";
      if (ref($p) =~ m/hash/is and my $c = $p->content)
       {$R->content = decodeBase64($c);                                         # Decode the data
       }
     }

    return $gitHub->response = $R;                                              # Return successful response
   }
  else
   {confess "Unexpected response from GitHub:\n", $r;                           # Confess to failure
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
qw(X_Runtime_rack),
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

sub new                                                                         # Create a new GitHub object.
 {my $curl = qx(curl -V);                                                       # Check Curl
  if ($curl =~ /command not found/)
   {confess "Command 𝗰𝘂𝗿𝗹 not found"
   }
  return bless {}
 }

sub list($)                                                                     # List the files and folders in a GitHub repository.\mRequired parameters: L<userid|/userid>, L<repository|/repository>.\mOptional parameters: L<gitFolder|/gitFolder>, L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.\mIf the list operation is successful, L<failed|/failed> is set to false and L<fileList|/fileList> is set to refer to an array of the file names found.\mIf the list operation fails then L<failed|/failed> is set to true and L<fileList|/fileList> is set to refer to an empty array.\mReturns the list of file names found or empty list if no files were found.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $user = $gitHub->userid;     $user or confess "userid required";
  my $repo = $gitHub->repository; $repo or confess "repository required";
  my $path = $gitHub->gitFolder || '';
  my $bran = $gitHub->refOrBranch(1);
  my $pat  = $gitHub->patKey(0);

  my $s = filePath("curl -si $pat $url",$user,$repo, qq(contents), $path.$bran);

  my $r = GitHub::Crud::Response::new($gitHub, $s);                             # Get response

  my ($status) = split / /, $r->Status;                                         # Check response code
  $gitHub->failed = $status != 200;

  if ($gitHub->failed)                                                          # No file list supplied
   {$gitHub->fileList = [];
   }
  else
   {for(@{$r->data})
     {bless $_, "GitHub::Crud::Response::Data";
     }
    $gitHub->fileList = [map{$_->name} @{$r->data}];                            # List of files
   }

  @{$gitHub->fileList}
 }

if (0 and !caller)
 {my $g = GitHub::Crud::new();
  $g->userid     = $testUserid;
  $g->repository = $testRepository;
  $g->gitFolder  = "images";
  say STDERR "list:\n", join ' ', $g->list;                                     # aaa.png bbb.png
 }

sub read($)                                                                     # Read data from a file on GitHub.\mRequired parameters: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> file to read.\mOptional parameters: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.\mIf the read operation is successful, L<failed|/failed> is set to false and L<readData|/readData> is set to the data read from the file.\mIf the read operation fails then L<failed|/failed> is set to true and L<readData|/readData> is set to B<undef>.\mReturns the data read or B<undef> if no file was found.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $user = $gitHub->userid;     $user or confess "userid required";
  my $repo = $gitHub->repository; $repo or confess "repository required";
  my $file = $gitHub->gitFile;    $file or confess "gitFile required";
  my $bran = $gitHub->refOrBranch(1);
  my $pat  = $gitHub->patKey(0);

  my $s = filePath("curl -si $pat $url",$user,$repo, qq(contents), $file.$bran);

  my $r = GitHub::Crud::Response::new($gitHub, $s);                             # Get response from GitHub

  my ($status) = split / /, $r->Status;                                         # Check response code
  $gitHub->failed = $status != 200;

  if ($gitHub->failed)                                                          # No file list supplied
   {$gitHub->readData = undef;
   }
  else
   {$gitHub->readData = decodeBase64($r->data->content);
   }

  $gitHub->readData
 }

if (0 and !caller)
 {my $g = GitHub::Crud::new();
  $g->userid     = $testUserid;
  $g->repository = $testRepository;
  $g->gitFile    = "test.html";
  my $s = $g->readData;
  say STDERR "Read:\n", dump($g->read);
 }

sub write($$)                                                                   # Write data into a GitHub file, creating the file if it is not already present.\mRequired parameters: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile>, L<patKey|/patKey>, L<writeData|/writeData>.\mOptional parameters: L<refOrBranch|/refOrBranch>.\mIf the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.
 {my ($gitHub, $data) = @_;                                                     # GitHub object, data to be written
  defined($data) or confess "data required";
  my $pat  = $gitHub->patKey(1);
  my $user = $gitHub->userid;     $user or confess "userid required";
  my $repo = $gitHub->repository; $repo or confess "repository required";
  my $file = $gitHub->gitFile;    $file or confess "gitFile required";
  my $bran = $gitHub->refOrBranch(0) || '?';

  $gitHub->read;                                                                # Read the file to get its sha it exists
  my $r    = $gitHub->response;                                                 # Get response
  my $sha  = $r->data->sha ? ', "sha": "'. $r->data->sha .'"' : '';             # Sha of existing file or blank string if no existing file
  my $denc = encodeBase64($data) =~ s/\n//gsr;

  writeFile(my $tmpFile = temporaryFile(),                                      # Write encoded content to temporary file
            qq({"message": "", "content": "$denc" $sha}));
  my $d = qq( -d @).$tmpFile;
  my $u = filePath($url, $user, $repo, qw(contents), $file.$bran.$d);
  my $s = "curl -si -X PUT $pat $u";                                            # Curl command
  my $R = GitHub::Crud::Response::new($gitHub, $s);                             # Execute command to create response
  unlink $tmpFile;                                                              # Cleanup

  my ($status) = split / /, $R->Status;                                         # Check response code
  my $success = $status == 200 ? 'updated' : $status == 201 ? 'created' : undef;# Updated, created
  $gitHub->failed = $success ? undef : 1;
  $success                                                                      # Return true on success
 }

if (0 and !caller)
 {my $g = GitHub::Crud::new();
  $g->userid     = $testUserid;
  $g->repository = $testRepository;
  $g->gitFile    = "test4.html";
  $g->personalAccessToken = $pat;
  my $d = (dateTimeStamp."\n") x 10;
  my $w = $g->write($d);
  my $r = $g->read;
  say STDERR $r;                                                                # 10 dateTimeStamps
 }

sub delete($)                                                                   # Delete a file already present on GitHub.\mRequired parameters: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile>, L<patKey|/patKey>.\mOptional parameters: L<refOrBranch|/refOrBranch>.\mIf the delete operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the delete was successful else false.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat  = $gitHub->patKey(1);
  my $user = $gitHub->userid;     $user or confess "userid required";
  my $repo = $gitHub->repository; $repo or confess "repository required";
  my $file = $gitHub->gitFile;    $file or confess "gitFile required";
  my $bran = $gitHub->refOrBranch(0);

  $gitHub->read;
  my $sha = sub
   {return '' if $gitHub->failed;
    ' -d \'{"message": "", "sha": "'. $gitHub->response->data->sha .'"}\'';
   }->();
  my $u = filePath($url, $user, $repo, qw(contents), $file.$bran.$sha);
  my $d = "curl -si -X DELETE $pat $u";
  my $r = GitHub::Crud::Response::new($gitHub, $d);
  my ($status) = split / /, $r->Status;                                         # Check response code
  my $success = $status == 200;
  $gitHub->failed = $success ? undef : 1;
  $success ? 1 : undef                                                          # Return true on success
 }

if (0 and !caller)
 {my $g = GitHub::Crud::new();
  $g->userid     = $testUserid;
  $g->repository = $testRepository;
  $g->gitFile    = "test4.html";
  $g->personalAccessToken = $pat;
  my $d = $g->delete;
  say STDERR "Delete:\n", dump($d);
 }

sub listWebHooks($)                                                             # List web hooks..\mRequired: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>. \mIf the list operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the list  operation was successful else false.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat  = $gitHub->patKey(1);
  my $user = $gitHub->userid;     $user or confess "userid required";
  my $repo = $gitHub->repository; $repo or confess "repository required";
  my $bran = $gitHub->refOrBranch(0);

  my $u    = filePath($url, $user, $repo, qw(hooks));
  my $s    = "curl -si $pat $u";
  my $r    = GitHub::Crud::Response::new($gitHub, $s);
  my ($status) = split / /, $r->Status;                                         # Check response code
  my $success = $status == 200;
  $gitHub->failed = $success ? undef : 1;
  $success ? 1 : undef                                                          # Return true on success
 }

if (0 and !caller)
 {my $g = GitHub::Crud::new();
  $g->userid     = $testUserid;
  $g->repository = $testRepository;
  $g->personalAccessToken = $pat;
  $g->listWebHooks;
 }

sub createPushWebHook($)                                                        # Create a web hook..\mRequired: L<userid|/userid>, L<repository|/repository>, L<url|/url>, L<patKey|/patKey>.\mOptional: L<secret|/secret>.\mIf the create operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the web hook was created successfully else false.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat    = $gitHub->patKey(1);
  my $user   = $gitHub->userid;     $user   or confess "userid required";
  my $repo   = $gitHub->repository; $repo   or confess "repository required";
  my $webUrl = $gitHub->url;        $webUrl or confess "url required";
  my $bran   = $gitHub->refOrBranch(0);
  my $secret = $gitHub->secret;

  my $sj = $secret ? qq(, "secret": "$secret") : '';                            # Secret for Json

  writeFile(my $tmpFile = temporaryFile(), my $json = <<END);                   # Write web hook definition
  {"name": "web", "active": true, "events": ["push"],
   "config": {"url": "$webUrl", "content_type": "json" $sj}
  }
END
  my $d = q( -d @).$tmpFile;
  my $u = filePath($url, $user, $repo, qw(hooks));
  my $s = "curl -si -X POST $pat $u $d";                                        # Create url
  my $r = GitHub::Crud::Response::new($gitHub, $s);
  my ($status) = split / /, $r->Status;                                         # Check response code
  my $success = $status == 201;
  unlink $tmpFile;                                                              # Cleanup
  $gitHub->failed = $success ? undef : 1;
  $success ? 1 : undef                                                          # Return true on success
 }

if (0 and !caller)
 {my $g = GitHub::Crud::new();
  $g->userid     = $testUserid;
  $g->repository = $testRepository;
  $g->url        = $testUrl;
  $g->secret     = $testSecret;
  $g->personalAccessToken = $pat;
  my $d = $g->createPushWebHook;
  say STDERR "Create web hook:\n", dump($d);
 }

#-------------------------------------------------------------------------------
# Tests
#-------------------------------------------------------------------------------

if (1 and !caller)
 {my $g = GitHub::Crud::new();
  $g->userid     = $testUserid;
  $g->repository = $testRepository;
  $g->gitFile    = "testFromAppaApps.html";
  $g->personalAccessToken = $pat;

  my $d = join '-', 1..9;

  say STDERR
     "Write : ", dump($g->write($d)),
   "\nRead 1: ", dump($g->read),
   "\nDelete: ", dump($g->delete),
   "\nRead 2: ", dump($g->read);
 }

#podDocumentation

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

Create a file by writing some of data to it, read the file to get its contents,
delete the file, then try to read the deleted file again:

 use GitHub::Crud;

  my $g = GitHub::Crud::new();
     $g->userid              = "...";
     $g->repository          = "test";
     $g->gitFile             = "test.html";
     $g->personalAccessToken = "...";

  my $d = join '-', 1..9;

  say STDERR
     "Write : ", dump($g->write($d)),
   "\nRead 1: ", dump($g->read),
   "\nDelete: ", dump($g->delete),
   "\nRead 2: ", dump($g->read);

Produces:

 Write : 'created';
 Read 1: "1-2-3-4-5-6-7-8-9"
 Delete: 1
 Read 2: undef

=head1 Description

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Attributes

Create a L<new()|/new> object and then set these attributes to specify your request to GitHub

=head2 branch :lvalue

Branch name (you should create this branch first) or omit it for the default branch which is usually 'master'


=head2 failed :lvalue

Defined if the last request to Github failed else B<undef>.


=head2 fileList :lvalue

Reference to an array of files produced by L<list|/list>


=head2 gitFile :lvalue

File name on GitHub - this name can contain '/'


=head2 gitFolder :lvalue

Folder name on GitHub - this name can contain '/'


=head2 personalAccessToken :lvalue

A personal access token with scope "public_repo" as generated on page: https://github.com/settings/tokens


=head2 readData :lvalue

Data produced by L<read|/read>


=head2 repository :lvalue

The name of your repository - you should create this repository first


=head2 response :lvalue

A reference to GitHub's response to the latest request


=head2 secret :lvalue

The secret for a web hook


=head2 url :lvalue

The url for a web hook


=head2 userid :lvalue

Your userid on GitHub


=head2 writeData :lvalue

Data to be written by L<write|/write>


=head1 Methods available

=head2 new()

Create a new GitHub object.


=head2 list($)

List the files and folders in a GitHub repository.

Required parameters: L<userid|/userid>, L<repository|/repository>.

Optional parameters: L<gitFolder|/gitFolder>, L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.

If the list operation is successful, L<failed|/failed> is set to false and L<fileList|/fileList> is set to refer to an array of the file names found.

If the list operation fails then L<failed|/failed> is set to true and L<fileList|/fileList> is set to refer to an empty array.

Returns the list of file names found or empty list if no files were found.

  1  $gitHub  GitHub object

=head2 read($)

Read data from a file on GitHub.

Required parameters: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> file to read.

Optional parameters: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.

If the read operation is successful, L<failed|/failed> is set to false and L<readData|/readData> is set to the data read from the file.

If the read operation fails then L<failed|/failed> is set to true and L<readData|/readData> is set to B<undef>.

Returns the data read or B<undef> if no file was found.

  1  $gitHub  GitHub object

=head2 write($$)

Write data into a GitHub file, creating the file if it is not already present.

Required parameters: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile>, L<patKey|/patKey>, L<writeData|/writeData>.

Optional parameters: L<refOrBranch|/refOrBranch>.

If the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.

  1  $gitHub  GitHub object
  2  $data    Data to be written

=head2 delete($)

Delete a file already present on GitHub.

Required parameters: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile>, L<patKey|/patKey>.

Optional parameters: L<refOrBranch|/refOrBranch>.

If the delete operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the delete was successful else false.

  1  $gitHub  GitHub object

=head2 listWebHooks($)

List web hooks..

Required: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>.

If the list operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the list  operation was successful else false.

  1  $gitHub  GitHub object

=head2 createPushWebHook($)

Create a web hook..

Required: L<userid|/userid>, L<repository|/repository>, L<url|/url>, L<patKey|/patKey>.

Optional: L<secret|/secret>.

If the create operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the web hook was created successfully else false.

  1  $gitHub  GitHub object


=head1 Index


1 L<branch|/branch>

2 L<createPushWebHook|/createPushWebHook>

3 L<delete|/delete>

4 L<failed|/failed>

5 L<fileList|/fileList>

6 L<gitFile|/gitFile>

7 L<gitFolder|/gitFolder>

8 L<list|/list>

9 L<listWebHooks|/listWebHooks>

10 L<new|/new>

11 L<personalAccessToken|/personalAccessToken>

12 L<read|/read>

13 L<readData|/readData>

14 L<repository|/repository>

15 L<response|/response>

16 L<secret|/secret>

17 L<url|/url>

18 L<userid|/userid>

19 L<write|/write>

20 L<writeData|/writeData>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# 𝗣𝗲𝗿𝗹
#podDocumentation
# curl -si -H "Authorization: token 0e8eb824527064941a528089ca7674695f5f1c15"  https://api.github.com/repos/philiprbrenan/horses/
# curl -si -H "Authorization: token 0e8eb824527064941a528089ca7674695f5f1c15"  https://api.github.com/repos/philiprbrenan/horses/contents
# curl -si -H "Authorization: token 0e8eb824527064941a528089ca7674695f5f1c15"  https://api.github.com/repos/philiprbrenan/horses/contents/images
# curl -si -H "Authorization: token 0e8eb824527064941a528089ca7674695f5f1c15"  https://api.github.com/repos/philiprbrenan/horses/contents/images/aaa.png
__DATA__
use Test::More tests => 1;

ok 1;
