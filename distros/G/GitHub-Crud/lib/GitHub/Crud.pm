#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Create, Read, Update, Delete files, commits, issues, and web hooks on GitHub.
# Per: https://developer.github.com/v3/
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017-2020
#-------------------------------------------------------------------------------
#podDocumentation
package GitHub::Crud;
use v5.16;
our $VERSION = 202102121;
use warnings FATAL => qw(all);
use strict;
use Carp              qw(confess);
use Data::Dump        qw(dump);
use Data::Table::Text qw(:all !fileList);
use Digest::SHA1      qw(sha1_hex);
use Date::Manip;
use Scalar::Util      qw(blessed reftype looks_like_number);
use Time::HiRes       qw(time);
use Encode            qw(encode decode);
use utf8;                                                                       # To allow utf8 constants for testing

sub url          { "https://api.github.com/repos" }                             # Github repository api url
sub api          { "https://api.github.com/" }                                  # Github api url
sub accessFolder { q(/etc/GitHubCrudPersonalAccessToken) };                     # Personal access tokens are stored in a file in this folder with the name of the userid of the L<GitHub> repository

my %shas;                                                                       # L<SHA> digests already seen - used to optimize write and delete

sub GitHub::Crud::Response::new($$)                                             #P Execute a request against L<GitHub> and decode the response
 {my ($gitHub, $request) = @_;                                                  # Github, request string

  my $R = bless {command=>$request}, "GitHub::Crud::Response";                  # Construct the response

  my $r = xxx $request, qr(HTTP);

  $r =~ s/\r//gs;                                                               # Internet line ends
  my ($http, @r) = split /\n/, $r;
  while(@r > 2 and $http =~ "HTTP" and $http =~ /100/)                          # Continue messages
   {shift @r; $http = shift @r;
   }

  if ($http and $http =~ "HTTP" and $http =~ /200|201|404|409|422/)
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
          else {$can{$name}++}                                                  # Update list of new methods required
         }
       }
      else
       {push @data, $_;
       }
     }

    if (keys %can)                                                              # List of new methods required
     {lll "Add the following fields to package GitHub::Crud::Response";
      say STDERR "  $_=> undef," for(sort keys %can);
     }

    if (@data)                                                                  # Save any data
     {my $j = join ' ', @data;
      my $p = $R->data = bless decodeJson($j), "GitHub::Crud::Response::Data";
      if (ref($p) =~ m/hash/is and my $c = $p->content)
       {$R->content = decodeBase64($c);                                         # Decode the data
       }
     }

    ($R->status) = split / /, $R->Status || $R->status || 200;                  # Save response status - github returns status == 0 when running as an action so we make it 200

    return $gitHub->response = $R;                                              # Return successful response
   }
  else
   {confess "Unexpected response from GitHub:\n$r\n$request\n";                 # Confess to failure
   }
 }

genHash(q(GitHub::Crud::Response),                                              # Attributes describing a response from L<GitHub>.
  Accept_Ranges                           => undef,
  access_control_allow_origin             => undef,
  Access_Control_Allow_Origin             => undef,
  access_control_expose_headers           => undef,
  Access_Control_Expose_Headers           => undef,
  cache_control                           => undef,
  Cache_Control                           => undef,
  Connection                              => undef,
  content_length                          => undef,
  Content_Length                          => undef,
  content_security_policy                 => undef,
  Content_Security_Policy                 => undef,
  content_type                            => undef,
  Content_Type                            => undef,
  content                                 => undef,                             # The actual content of the file from L<GitHub>.
  data                                    => undef,                             # The data received from L<GitHub>, normally in L<json> format.
  date                                    => undef,
  Date                                    => undef,
  etag                                    => undef,
  ETag                                    => undef,
  Expires                                 => undef,
  last_modified                           => undef,
  Last_Modified                           => undef,
  Link                                    => undef,
  Location                                => undef,
  referrer_policy                         => undef,
  Referrer_Policy                         => undef,
  server                                  => undef,
  Server                                  => undef,
  Source_Age                              => undef,
  Status                                  => undef,
  status                                  => undef,                             # Our version of Status.
  strict_transport_security               => undef,
  Strict_Transport_Security               => undef,
  vary                                    => undef,
  Vary                                    => undef,
  Via                                     => undef,
  x_accepted_oauth_scopes                 => undef,
  X_Accepted_OAuth_Scopes                 => undef,
  X_Cache_Hits                            => undef,
  X_Cache                                 => undef,
  x_content_type_options                  => undef,
  X_Content_Type_Options                  => undef,
  X_Content_Type                          => undef,
  X_Fastly_Request_ID                     => undef,
  x_frame_options                         => undef,
  X_Frame_Options                         => undef,
  X_Geo_Block_List                        => undef,
  x_github_media_type                     => undef,
  X_GitHub_Media_Type                     => undef,
  x_github_request_id                     => undef,
  X_GitHub_Request_Id                     => undef,
  x_oauth_scopes                          => undef,
  X_OAuth_Scopes                          => undef,
  x_ratelimit_limit                       => undef,
  X_RateLimit_Limit                       => undef,
  x_ratelimit_remaining                   => undef,
  X_RateLimit_Remaining                   => undef,
  x_ratelimit_reset                       => undef,
  X_RateLimit_Reset                       => undef,
  x_ratelimit_used                        => undef,
  X_RateLimit_Used                        => undef,
  X_Runtime_rack                          => undef,
  X_Served_By                             => undef,
  X_Timer                                 => undef,
  x_xss_protection                        => undef,
  X_XSS_Protection                        => undef,
 );

genHash(q(GitHub::Crud::Response::Data),                                        # Response from a request made to L<GitHub>.
  command                                 => undef,
  content                                 => undef,
  documentation_url                       => undef,
  download_url                            => undef,
  encoding                                => undef,
  git                                     => undef,
  git_url                                 => undef,
  html                                    => undef,
  html_url                                => undef,
  _links                                  => undef,
  message                                 => undef,
  name                                    => undef,
  path                                    => undef,
  self                                    => undef,
  sha                                     => undef,
  size                                    => undef,
  type                                    => undef,
  url                                     => undef,
 );

sub getSha($)                                                                   #P Compute L<sha> for data after encoding any unicode characters as utf8.
 {my ($data) = @_;                                                              # String possibly containing non ascii code points

  my $length = length($data);
  my $blob   = 'blob' . " $length\0" . $data;
  utf8::encode($blob);
  my $r = eval{sha1_hex($blob)};
  confess $@ if $@;
  $r
 }

if (0)                                                                          # Test L<sha>
 {my $sha = getSha("<h1>Hello World</h1>\n");
  my $Sha = "f3e333e80d224c631f2ff51b9b9f7189ad349c15";
  unless($sha eq $Sha)
   {confess "Wrong SHA: $sha".
            "Should be: $Sha";
   }
  confess "getSha success";
 }

sub shaKey($;$)                                                                 #P Add a L<SHA> key to a L<url>
 {my ($gitHub, $fileData) = @_;                                                 # Github, optional fileData to specify the file to use if it is not gitFile
  filePath($gitHub->repository,
   $fileData ? ($fileData->path, $fileData->name) : $gitHub->gitFile)
 }

sub saveSha($$)                                                                 #P Save the L<sha> of a file
 {my ($gitHub, $fileData) = @_;                                                 # Github, file details returned by list or exists
  $shas{$gitHub->shaKey($fileData)} = $fileData->sha;
 }

sub copySha($)                                                                  #P Save the L<sha> of a file  just read to a file just about to be written
 {my ($gitHub) = @_;                                                            # Github
  $shas{$gitHub->shaKey}  = $gitHub->response->data->sha;
 }

sub getExistingSha($)                                                           #P Get the L<sha> of a file that already exists
 {my ($gitHub) = @_;                                                            # Github
  my $s = $shas{$gitHub->shaKey};                                               # Get the L<sha> from the cache
  return $s if defined $s;                                                      # A special L<sha> of 0 means the file was deleted
  my $r = $gitHub->exists;                                                      # Get the L<sha> of the file via exists if the file exists
  return $r->sha if $r;                                                         # L<sha> of existing file
  undef                                                                         # Undef if no such file
 }

sub deleteSha($)                                                                #P Delete a L<sha> that is no longer valid
 {my ($gitHub) = @_;                                                            # Github
  $shas{$gitHub->shaKey} = undef                                                # Mark the L<sha> as deleted
 }

sub qm($)                                                                       #P Quotemeta extended to include undef
 {my ($s) = @_;                                                                 # String to quote
  return '' unless $s;
  $s =~ s((\'|\"|\\)) (\\$1)gs;
  $s =~ s(\s) (%20)gsr;                                                         # Url encode blanks
 }

sub patKey($)                                                                   #P Create an authorization header by locating an appropriate personal access token
 {my ($gitHub) = @_;                                                            # GitHub

  $gitHub->loadPersonalAccessToken unless $gitHub->personalAccessToken;         # Load a personal access token if none has been supplied

  if (my $pat = $gitHub->personalAccessToken)                                   # User supplied personal access token explicitly
   {return "-H \"Authorization: token $pat\""
   }

  confess "Personal access token required with scope \"public_repo\"".          # We must have a personal access token to do anything useful!
          " as generated on page:\nhttps://github.com/settings/tokens";
 }

sub refOrBranch($$)                                                             #P Add a ref or branch keyword
 {my ($gitHub, $ref) = @_;                                                      # Github, whether to use ref rather than branch
  my $b = $gitHub->branch;
  return "?ref=$b"    if  $ref and $b;
  return "?branch=$b" if !$ref and $b;
  ''
 }

sub gitHub(%)                                                                   #P Create a test L<GitHub> object
 {my (%options) = @_;                                                           # Options
  GitHub::Crud::new
   (userid           => q(philiprbrenan),
    repository       => q(aaa),
    confessOnFailure => 1,
    @_);
 }

#D1 Constructor                                                                 # Create a L<github> object with the specified attributes describing the interface with L<github>.

sub new(@)                                                                      # Create a new L<GitHub> object with attributes as described at: L<GitHub::Crud Definition>.
 {my (%attributes) = @_;                                                        # Attribute values

  my $curl = qx(curl -V);                                                       # Check Curl
  if ($curl =~ /command not found/)
   {confess "Command curl not found"
   }

  my $g = genHash(__PACKAGE__,                                                  # Attributes describing the interface with L<github>.
    body                         => undef,                                      #I The body of an issue.
    branch                       => undef,                                      #I Branch name (you should create this branch first) or omit it for the default branch which is usually 'master'.
    confessOnFailure             => undef,                                      #I Confess to any failures
    failed                       => undef,                                      #  Defined if the last request to L<GitHub> failed else B<undef>.
    fileList                     => undef,                                      #  Reference to an array of files produced by L<list|/list>.
    gitFile                      => undef,                                      #I File name on L<GitHub> - this name can contain '/'. This is the file to be read from, written to, copied from, checked for existence or deleted.
    gitFolder                    => undef,                                      #I Folder name on L<GitHub> - this name can contain '/'.
    message                      => undef,                                      #I Optional commit message
    nonRecursive                 => undef,                                      #I Fetch only one level of files with L<list>.
    personalAccessToken          => undef,                                      #I A personal access token with scope "public_repo" as generated on page: https://github.com/settings/tokens.
    personalAccessTokenFolder    => accessFolder,                               #I The folder into which to save personal access tokens. Set to q(/etc/GitHubCrudPersonalAccessToken) by default.
    private                      => undef,                                      #I Whether the repository being created should be private or not.
    readData                     => undef,                                      #  Data produced by L<read|/read>.
    repository                   => undef,                                      #I The name of the repository to be worked on minus the userid - you should create this repository first manually.
    response                     => undef,                                      #  A reference to L<GitHub>'s response to the latest request.
    secret                       => undef,                                      #I The secret for a web hook - this is created by the creator of the web hook and remembered by L<GitHub>,
    title                        => undef,                                      #I The title of an issue.
    webHookUrl                   => undef,                                      #I The url for a web hook.
    userid                       => undef,                                      #I Userid on L<GitHub> of the repository to be worked on.
   );

  $g->$_ = $attributes{$_} for sort keys %attributes;

  $g
 }

#D1 Files                                                                       # File actions on the contents of L<GitHub> repositories.

sub list($)                                                                     # List all the files contained in a L<GitHub> repository or all the files below a specified folder in the repository.\mRequired attributes: L<userid|/userid>, L<repository|/repository>.\mOptional attributes: L<gitFolder|/gitFolder>, L<refOrBranch|/refOrBranch>, L<nonRecursive|/nonRecursive>, L<patKey|/patKey>.\mUse the L<gitFolder|/gitFolder> parameter to specify the folder to start the list from, by default, the listing will start at the root folder of your repository.\mUse the L<nonRecursive|/nonRecursive> option if you require only the files in the start folder as otherwise all the folders in the start folder will be listed as well which might take some time.\mIf the list operation is successful, L<failed|/failed> is set to false and L<fileList|/fileList> is set to refer to an array of the file names found.\mIf the list operation fails then L<failed|/failed> is set to true and L<fileList|/fileList> is set to refer to an empty array.\mReturns the list of file names found or empty list if no files were found.
 {my ($gitHub) = @_;                                                            # GitHub
  my $r = sub                                                                   # Get contents
   {my $user = qm $gitHub->userid;     $user or confess "userid required";
    my $repo = qm $gitHub->repository; $repo or confess "repository required";
    my $path = qm $gitHub->gitFolder || '';
    my $bran = qm $gitHub->refOrBranch(1);
    my $pat  = $gitHub->patKey(0);
    my $url  = url;
    my $s = filePath
     ("curl -si $pat $url", $user, $repo, qq(contents), $path.$bran);
    GitHub::Crud::Response::new($gitHub, $s);
   }->();

  my $failed = $gitHub->failed = $r->status != 200;                             # Check response code
  $failed and $gitHub->confessOnFailure and confess dump($gitHub);              # Confess to any failure if so requested

  $gitHub->fileList = [];
  if (!$failed and reftype($r->data) =~ m(array)i)                              # Array of file  details
   {for(@{$r->data})                                                            # Objectify and save L<sha> digests from file descriptions retrieved by this call
     {bless $_, "GitHub::Crud::Response::Data";
      saveSha($gitHub, $_);
     }

    my $path = $gitHub->gitFolder || '';
    my @d = map{filePath $path, $_->name} grep {$_->type eq "dir"}  @{$r->data};# Folders
    my @f = map{filePath $path, $_->name} grep {$_->type eq "file"} @{$r->data};# Files

    unless($gitHub->nonRecursive)                                               # Get the contents of sub folders unless otherwise specified
     {for my $d(@d)
       {my $p = $gitHub->gitFolder = $d;
        push @f, $gitHub->list;
       }
     }
    $gitHub->gitFolder = $path;                                                 # Restore path supplied by the user
    $gitHub->fileList  = [@f];                                                  # List of files not directories
   }
  @{$gitHub->fileList}
 }

sub specialFileData($)                                                          # Do not encode or decode data with a known file signature
 {my ($d) = @_;                                                                 # String to check
  my $h = '';
  if ($d and length($d) > 8)                                                    # Read file magic number
   {for my $e(0..7)
     {$h .= sprintf("%x", ord(substr($d, $e, 1)));
     }
    return 1 if $h =~ m(\A504b)i;                                               # PK Zip
    return 1 if $h =~ m(\Ad0cf11e0)i;                                           # OLE files
    return 1 if $h =~ m(\Affd8ff)i;                                             # Jpg
    return 1 if $h =~ m(\A89504e470d0a1a0a)i;                                   # Png
    return 1 if $h =~ m(\A4D546864)i;                                           # Midi
    return 1 if $h =~ m(\A49443340)i;                                           # Mp3
   }
  0                                                                             # Not a special file
 }

sub read($;$)                                                                   # Read data from a file on L<GitHub>.\mRequired attributes: L<userid|/userid>, L<repository|/repository>.\mOptional attributes: L<gitFile|/gitFile> = the file to read, L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.\mIf the read operation is successful, L<failed|/failed> is set to false and L<readData|/readData> is set to the data read from the file.\mIf the read operation fails then L<failed|/failed> is set to true and L<readData|/readData> is set to B<undef>.\mReturns the data read or B<undef> if no file was found.
 {my ($gitHub, $File) = @_;                                                     # GitHub, file o read if not specified in gitFile

  my $user = qm $gitHub->userid;          $user or confess "userid required";
  my $repo = qm $gitHub->repository;      $repo or confess "repository required";
  my $file = qm($File//$gitHub->gitFile); $file or confess "gitFile required";
  my $bran = qm $gitHub->refOrBranch(1);
  my $pat  = $gitHub->patKey(0);

  my $url  = url;
  my $s = filePath(qq(curl -si $pat $url),
                   $user, $repo, qq(contents), $file.$bran);
  my $r = GitHub::Crud::Response::new($gitHub, $s);                             # Get response from GitHub
  my $failed = $gitHub->failed = $r->status != 200;                             # Check response code
  $failed and $gitHub->confessOnFailure and confess dump($gitHub);              # Confess to any failure if so requested

  if ($failed)                                                                  # Decode data unless read failed
   {$gitHub->readData = undef;
   }
  else                                                                          # Decode data
   {my $d = decodeBase64($r->data->content);
    $gitHub->readData = specialFileData($d) ? $d : decode "UTF8", $d;           # Convert to utf unless a known file format
   }

  $gitHub->readData
 }

sub write($$;$)                                                                 # Write utf8 data into a L<GitHub> file.\mRequired attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>. Either specify the target file on:<github> using the L<gitFile|/gitFile> attribute or supply it as the third parameter.  Returns B<true> on success else L<undef>.
 {my ($gitHub, $data, $File) = @_;                                              # GitHub object, data to be written, optionally the name of the file on github

  unless($data)                                                                 # No data supplied so delete the file
   {if ($File)
     {my $file = $gitHub->file;
      $gitHub->file = $File;
      $gitHub->delete;
      $gitHub->file = $file;
     }
    else
     {$gitHub->delete;
     }
    return 'empty';                                                             # Success
   }

  my $pat  = $gitHub->patKey(1);
  my $user = qm $gitHub->userid;          $user or confess "userid required";
  my $repo = qm $gitHub->repository;      $repo or confess "repository required";
  my $file = qm($File//$gitHub->gitFile); $file or confess "gitFile required";
  my $bran = qm $gitHub->refOrBranch(0) || '?';
  my $mess = qm $gitHub->message;

  if (!specialFileData($data))                                                  # Send the data as utf8 unless it is a special file
   {use Encode 'encode';
    $data  = encode('UTF-8', $data);
   }

  my $url  = url;
  my $save = $gitHub->gitFile;                                                  # Save any existing file name as we might need to update it to get the sha if the target file was supplied as a parameter to this sub
  $gitHub->gitFile = $File if $File;                                            # Set target file name so we can get its sha
  my $s    = $gitHub->getExistingSha || getSha($data);                          # Get the L<sha> of the file if the file exists
  $gitHub->gitFile = $save;                                                     # Restore file name
  my $sha = $s ? ', "sha": "'. $s .'"' : '';                                    # L<sha> of existing file or blank string if no existing file

# if ($s and my $S = getSha($data))                                             # L<sha> of new data
#  {if ($s eq $S)                                                               # Duplicate if the L<sha>s match
#    {$gitHub->failed = undef;
#     return 1;
#    }
#  }

  my $denc = encodeBase64($data) =~ s/\n//gsr;

  my $branch = sub                                                              # It seems we must put the branch in the json file though the documentation seems to imply it can go in the url or the json
   {my $b = $gitHub->branch;
    return qq(, "branch" : "$b") if $b;
    q()
   }->();

  my $j = qq({"message": "$mess", "content": "$denc" $sha $branch});
  my $t = writeFile(undef, $j);                                                 # Write encoded content to temporary file
  my $d = qq(-d @).$t;
  my $u = filePath($url, $user, $repo, qw(contents), $file.$bran);
  my $c = qq(curl -si -X PUT $pat $u $d);                                       # Curl command
  my $r = GitHub::Crud::Response::new($gitHub, $c);                             # Execute command to create response
  unlink $t;                                                                    # Cleanup

  my $status = $r->status;                                                      # Check response code
  my $success = $status == 200 ? 'updated' : $status == 201 ? 'created' : undef;# Updated, created
  $gitHub->failed = $success ? undef : 1;
  !$success and $gitHub->confessOnFailure and confess dump($gitHub);            # Confess to any failure if so requested

  $success                                                                      # Return true on success
 }

sub readBlob($$)                                                                # Read a L<blob> from L<GitHub>.\mRequired attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>. Returns the content of the L<blob> identified by the specified L<sha>.
 {my ($gitHub, $sha) = @_;                                                      # GitHub object, data to be written
  defined($sha) or confess "sha required";

  my $pat  = $gitHub->patKey(1);
  my $user = qm $gitHub->userid;     $user or confess "userid required";
  my $repo = qm $gitHub->repository; $repo or confess "repository required";
  my $url  = url;

  my $u = filePath($url, $user, $repo, qw(git blobs), $sha);                    # Url
  my $c = qq(curl -si $pat $u);                                                 # Curl command
  my $r = GitHub::Crud::Response::new($gitHub, $c);                             # Execute command to create response

  my $status = $r->status;                                                      # Check response code
  my $success = $status == 200;
  $gitHub->failed = $success ? undef : 1;
  !$success and $gitHub->confessOnFailure and confess dump($gitHub);            # Confess to any failure if so requested

  $success ? decodeBase64($gitHub->response->data->content) : undef             # Return content on success else undef
 }

sub writeBlob($$)                                                               # Write data into a L<GitHub> as a L<blob> that can be referenced by future commits.\mRequired attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>. Returns the L<sha> of the created L<blob> or L<undef> in a failure occurred.
 {my ($gitHub, $data) = @_;                                                     # GitHub object, data to be written
  defined($data) or confess "binary data required";

  my $pat  = $gitHub->patKey(1);
  my $user = qm $gitHub->userid;     $user or confess "userid required";
  my $repo = qm $gitHub->repository; $repo or confess "repository required";
  my $url  = url;

  my $denc = encodeBase64($data) =~ s/\n//gsr;
  my $t = writeTempFile(qq({"content": "$denc", "encoding" : "base64"}));       # Write encoded content to temporary file
  my $d = qq(-d @).$t;
  my $u = filePath($url, $user, $repo, qw(git blobs));
  my $c = qq(curl -si -X POST $pat $u $d);                                      # Curl command
  my $r = GitHub::Crud::Response::new($gitHub, $c);                             # Execute command to create response
  unlink $t;                                                                    # Cleanup

  my $status = $r->status;                                                      # Check response code
  my $success = $status == 200 ? 'updated' : $status == 201 ? 'created' : undef;# Updated, created
  $gitHub->failed = $success ? undef : 1;
  !$success and $gitHub->confessOnFailure and confess dump($gitHub);            # Confess to any failure if so requested

  $success ? $gitHub->response->data->sha : undef                               # Return sha of blob on success
 }

sub copy($$)                                                                    # Copy a source file from one location to another target location in your L<GitHub> repository, overwriting the target file if it already exists.\mRequired attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be copied.\mOptional attributes: L<refOrBranch|/refOrBranch>.\mIf the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.
 {my ($gitHub, $target) = @_;                                                   # GitHub object, the name of the file to be created
  defined($target) or confess "Specify the name of the file to be copied to";
  my $r = $gitHub->read;                                                        # Read the content of the source file
  if (defined $r)
   {my $file = $gitHub->gitFile;                                                # Save current source file
    my $sha  = $gitHub->response->data->sha;                                    # L<sha> of last file read
    $gitHub->gitFile = $target;                                                 # Set target file as current file
    my $R = $gitHub->write($r);                                                 # Write content to target file
    $gitHub->copySha;                                                           # Copy the L<sha> from the file just read
    $gitHub->gitFile = $file;                                                   # Restore source file
    return $R;                                                                  # Return response from write
   }
  undef                                                                         # Failed
 }

sub exists($)                                                                   # Test whether a file exists on L<GitHub> or not and returns an object including the B<sha> and B<size> fields if it does else L<undef>.\mRequired attributes: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> file to test.\mOptional attributes: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.
 {my ($gitHub) = @_;                                                            # GitHub object
  my @file = split /\//, $gitHub->gitFile;
  confess "gitFile required to name the file to be checked" unless @file;
  pop @file;
  my $folder            = $gitHub->gitFolder;
  my $nonRecursive      = $gitHub->nonRecursive;
  $gitHub->gitFolder    = filePath(@file);
  $gitHub->nonRecursive = 1;
  my $r = $gitHub->list;                                                        # Get a file listing
  $gitHub->gitFolder    = $folder;
  $gitHub->nonRecursive = $nonRecursive;

  if (!$gitHub->failed and reftype($gitHub->response->data) =~ m(array)i)       # Look for requested file in file listing
   {for(@{$gitHub->response->data})
     {return $_ if $_->path eq $gitHub->gitFile;
     }
   }
  undef
 }

sub rename($$)                                                                  # Rename a source file on L<GitHub> if the target file name is not already in use.\mRequired attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be renamed.\mOptional attributes: L<refOrBranch|/refOrBranch>.\mReturns the new name of the file B<renamed> if the rename was successful else B<undef> if the rename failed.
 {my ($gitHub, $target) = @_;                                                   # GitHub object, the new name of the file
  my $file = $gitHub->gitFile;
  $gitHub->gitFile = $target;
  return undef if $gitHub->exists;
  $gitHub->gitFile = $file;
  $gitHub->copy($target);
  $gitHub->gitFile = $target;
  if ($gitHub->exists)
   {$gitHub->gitFile = $file;
    return $target if $gitHub->delete;
    confess "Failed to delete source file $file";
   }
  undef
 }

sub delete($)                                                                   # Delete a file from L<GitHub>.\mRequired attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be deleted.\mOptional attributes: L<refOrBranch|/refOrBranch>.\mIf the delete operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the delete was successful else false.
 {my ($gitHub) = @_;                                                            # GitHub object

  my $pat  = $gitHub->patKey(1);
  my $user = qm $gitHub->userid;     $user or confess "userid required";
  my $repo = qm $gitHub->repository; $repo or confess "repository required";
  my $file = qm $gitHub->gitFile;    $file or confess "file to delete required";
  my $bran = qm $gitHub->refOrBranch(0);
  my $url  = url;

  my $s = $gitHub->getExistingSha;                                              # L<sha> of existing file or undef
  return 2 unless $s;                                                           # File already deleted
  my $sha = ' -d \'{"message": "", "sha": "'. $s .'"}\'';
  my $u = filePath($url, $user, $repo, qw(contents), $file.$bran.$sha);
  my $d = "curl -si -X DELETE $pat $u";
  my $r = GitHub::Crud::Response::new($gitHub, $d);
  my $success = $r->status == 200;                                              # Check response code
  $gitHub->deleteSha  if $success;                                              # The L<sha> is no longer valid
  $gitHub->failed = $success ? undef : 1;
  !$success and $gitHub->confessOnFailure and confess dump($gitHub);            # Confess to any failure if so requested
  $success ? 1 : undef                                                          # Return true on success
 }

#D1 Repositories                                                                # Perform actions on L<github> repositories.

sub getRepository($)                                                            # Get the overall details of a repository
 {my ($gitHub) = @_;                                                            # GitHub object

  my $pat    = $gitHub->patKey(1);
  my $user   = qm $gitHub->userid;     $user or confess "userid required";
  my $repo   = qm $gitHub->repository; $repo or confess "repository required";
  my $url    = url;

  my $c = qq(curl -si $pat $url/$user/$repo);
  my $r = GitHub::Crud::Response::new($gitHub, $c);
  my $success = $r->status == 200;                                              # Check response code
  !$success and $gitHub->confessOnFailure and confess dump([$gitHub, $c]);      # Confess to any failure if so requested

  $r
 }

sub listCommits($)                                                              # List all the commits in a L<GitHub> repository.\mRequired attributes: L<userid|/userid>, L<repository|/repository>.
 {my ($gitHub) = @_;                                                            # GitHub object

  my $pat    = $gitHub->patKey(1);
  my $user   = qm $gitHub->userid;     $user or confess "userid required";
  my $repo   = qm $gitHub->repository; $repo or confess "repository required";
  my $url    = url;

  my $c = qq(curl -si $pat $url/$user/$repo/branches);

  my $r = GitHub::Crud::Response::new($gitHub, $c);
  my $success = $r->status == 200;                                              # Check response code
  !$success and $gitHub->confessOnFailure and confess dump($gitHub);            # Confess to any failure if so requested

  $r
 }

sub listCommitShas($)                                                           # Create {commit name => sha} from the results of L<listCommits>.
 {my ($commits) = @_;                                                           # Commits from L<listCommits>

  return undef unless my $data = $commits->data;                                # Commits array
  {map {$$_{name} => $$_{commit}{sha}} @$data}                                  # Commits hash
 }

sub writeCommit($$@)                                                            # Write all the files in a B<$folder> (or just the the named files) into a L<GitHub> repository in parallel as a commit on the specified branch.\mRequired attributes: L<userid|/userid>, L<repository|/repository>, L<refOrBranch|/refOrBranch>.
 {my ($gitHub, $folder, @files) = @_;                                           # GitHub object, file prefix to remove, files to write

  -d $folder or confess "No such folder";                                       # Folder does not exist

  my $pat    = $gitHub->patKey(1);
  my $user   = qm $gitHub->userid;     $user or confess "userid required";
  my $repo   = qm $gitHub->repository; $repo or confess "repository required";
  my $bran   = $gitHub->branch;        $bran or confess "branch required";
  my $url    = url;

  my @sha = processFilesInParallel sub                                          # Create blobs for each file
   {my ($source) = @_;
    my $target   = $gitHub->gitFile = swapFilePrefix($source, $folder);
    [$source, $target, $gitHub->writeBlob(readBinaryFile($source))]
   }, undef, @files ? @files : searchDirectoryTreesForMatchingFiles($folder);

  my $tree  = sub                                                               # Create the tree
   {my @t;
    for my $f(@sha)                                                             # Load files into a tree
     {my ($s, $t, $b) = @$f;
      push @t, <<END;
 {"path" : "$t",
  "mode" : "100644",
  "type" : "blob",
  "sha"  : "$b"
 }
END
     }

    my $t = join ",\n", @t;                                                     # Assemble tree
    my $j = qq({"tree" : [$t]});                                                # Json describing tree
    my $f = writeTempFile($j);                                                  # Write Json
    my $c = qq(curl -si -X POST $pat -d \@$f $url/$user/$repo/git/trees);

    my $r = GitHub::Crud::Response::new($gitHub, $c);
    my $success = $r->status == 201;                                            # Check response code
    unlink $f;                                                                  # Cleanup

    $success or confess "Unable to create tree: ".dump($r);

    $r
   }->();

  my $parents = sub                                                             # Prior commits
   {my %c = listCommitShas $gitHub->listCommits;
    my $b = $gitHub->branch;
    return '' unless my $s = $c{$b};
    qq(, "parents" : ["$s"])
   }->();

  my $commit = sub                                                              # Create a commit to hold the tree
   {my $s = $tree->data->sha;
    my $d = dateTimeStamp;
    my $j = <<END;
{  "message" : "Committed by GitHub::Crud on: $d"
 , "tree"    : "$s"
    $parents
}
END
    my $f = writeFile(undef, $j);                                               # Write json

    my $c = qq(curl -si -X POST $pat -d \@$f $url/$user/$repo/git/commits);     # Execute json

    my $r = GitHub::Crud::Response::new($gitHub, $c);
    my $success = $r->status == 201;                                            # Check response code
    unlink $f;                                                                  # Cleanup

    $success or confess "Unable to create commit: ".dump($r);

    $r
   }->();

  my $branch = sub                                                              # Update branch - if this fails we will try a force as the next step
   {my $s = $commit->data->sha;
    my $f = writeFile(undef, <<END);
{
  "ref": "refs/heads/$bran",
  "sha": "$s"
}
END
    my $c = qq(curl -si -X POST $pat -d \@$f $url/$user/$repo/git/refs);
    my $r = GitHub::Crud::Response::new($gitHub, $c);
    my $success = $r->status == 201;                                            # Check response code
    unlink $f;                                                                  # Cleanup

    $r
   }->();

  my $status = $branch->status;                                                 # Creation status
  if    ($branch->status == 201) {return $branch}                               # Branch created
  elsif ($branch->status == 422)                                                # Update existing branch
   {my $branchUpdate = sub
     {my $s = $commit->data->sha;
      my $f = writeFile(undef, <<END);
{ "sha": "$s",
  "force": true
}
END
      my $c = qq(curl -si -X PATCH $pat -d \@$f $url/$user/$repo/git/refs/heads/$bran);
      my $r = GitHub::Crud::Response::new($gitHub, $c);
      my $success = $r->status == 200;                                          # Check response code
      unlink $f;                                                                # Cleanup

      $success or confess "Unable to update branch: ".dump($r);

      $r
     }->();
    return $branchUpdate;
   }

  confess "Unable to create/update branch: $bran";
 }

sub listWebHooks($)                                                             # List web hooks associated with your L<GitHub> repository.\mRequired: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>. \mIf the list operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the list  operation was successful else false.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat  = $gitHub->patKey(1);
  my $user = qm $gitHub->userid;     $user or confess "userid required";
  my $repo = qm $gitHub->repository; $repo or confess "repository required";
  my $bran = qm $gitHub->refOrBranch(0);
  my $url  = url;

  my $u    = filePath($url, $user, $repo, qw(hooks));
  my $s    = "curl -si $pat $u";
  my $r    = GitHub::Crud::Response::new($gitHub, $s);
  my $success = $r->status =~ m(200|201);                                       # Present or not present
  $gitHub->failed = $success ? undef : 1;
  !$success and $gitHub->confessOnFailure and confess dump($gitHub);            # Confess to any failure if so requested
  $success ? $gitHub->response->data : undef                                    # Return reference to array of web hooks on success. If there are no web hooks set then the referenced array will be empty.
 }

sub createPushWebHook($)                                                        # Create a web hook for your L<GitHub> userid.\mRequired: L<userid|/userid>, L<repository|/repository>, L<url|/url>, L<patKey|/patKey>.\mOptional: L<secret|/secret>.\mIf the create operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the web hook was created successfully else false.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat    = $gitHub->patKey(1);
  my $user   = qm $gitHub->userid;     $user   or confess "userid required";
  my $repo   = qm $gitHub->repository; $repo   or confess "repository required";
  my $webUrl = qm $gitHub->webHookUrl; $webUrl or confess "url required";
  my $bran   = qm $gitHub->refOrBranch(0);
  my $secret = $gitHub->secret;
  my $sj     = $secret ? qq(, "secret": "$secret") : '';                        # Secret for Json
  my $url    = url;

  $webUrl =~ m(\Ahttps?://) or confess                                          # Check that we are using a url like thing for the web hook or complain
   "Web hook has no scheme, should start with https?:// not:\n$webUrl";

  owf(my $tmpFile = temporaryFile(), my $json = <<END);                         # Write web hook definition
  {"name": "web", "active": true, "events": ["push"],
   "config": {"url": "$webUrl", "content_type": "json" $sj}
  }
END
  my $d = q( -d @).$tmpFile;
  my $u = filePath($url, $user, $repo, qw(hooks));
  my $s = "curl -si -X POST $pat $u $d";                                        # Create url
  my $r = GitHub::Crud::Response::new($gitHub, $s);

  my $success = $r->status == 201;                                              # Check response code
  unlink $tmpFile;                                                              # Cleanup
  $gitHub->failed = $success ? undef : 1;
  !$success and $gitHub->confessOnFailure and confess dump($gitHub);            # Confess to any failure if so requested
  $success ? 1 : undef                                                          # Return true on success
 }

sub listRepositories($)                                                         # List the repositories accessible to a user on L<GitHub>.\mRequired: L<userid|/userid>.\mReturns details of the repositories.
 {my ($gitHub) = @_;                                                            # GitHub object

  my $pat    = $gitHub->patKey(1);
  my $user   = qm $gitHub->userid; $user or confess "userid required";
  my $url    = api;

  my $u = filePath($url, qw(user repos));                                       # Request  url
  my $s = "curl -si $pat $u";                                                   # Create url
  my $r = GitHub::Crud::Response::new($gitHub, $s);
  my $success = $r->status == 200;                                              # Check response code
  $gitHub->failed = $success ? undef : 1;
  !$success and $gitHub->confessOnFailure and confess dump($gitHub);            # Confess to any failure if so requested
  $success ? $r->data->@* : undef                                               # Return a list of repositories on success
 }

sub createRepository($)                                                         # Create a repository on L<GitHub>.\mRequired: L<userid|/userid>, L<repository|/repository>.\mReturns true if the issue was created successfully else false.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat    = $gitHub->patKey(1);
  my $user   = qm $gitHub->userid;     $user   or confess "userid required";
  my $repo   = qm $gitHub->repository; $repo   or confess "repository required";
  my $private= $gitHub->private ? q(, "private":true) : q();                    # Private or not
  my $url    = api;

  my $json = qq({"name":"$repo", "auto_init":true $private});                   # Issue in json
  my $tmpFile = writeFile(undef, $json);                                        # Write repo definition
  my $d = q( -d @).$tmpFile;
  my $u = filePath($url, qw(user repos));                                       # Request  url
  my $s = "curl -si -X POST $pat $u $d";                                        # Create url
  my $r = GitHub::Crud::Response::new($gitHub, $s);
  my $success = $r->status == 201;                                              # Check response code
  unlink $tmpFile;                                                              # Cleanup
  $gitHub->failed = $success ? undef : 1;
  !$success and $gitHub->confessOnFailure and confess dump($gitHub);            # Confess to any failure if so requested
  $success ? 1 : undef                                                          # Return true on success
 }

sub createRepositoryFromSavedToken($$;$$)                                       # Create a repository on L<GitHub> using an access token either as supplied or saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.\mReturns true if the issue was created successfully else false.
 {my ($userid, $repository, $private, $accessFolderOrToken) = @_;               # Userid on GitHub, the repository name, true if the repo is private, location of access token.
  my $g = GitHub::Crud::new;
  $g->userid                    = $userid;
  $g->repository                = $repository;
  $g->private                   = $private;
  $g->personalAccessTokenFolder = $accessFolderOrToken;
  $g->loadPersonalAccessToken;
  $g->confessOnFailure          = 0;
  $g->createRepository;
 }

sub createIssue($)                                                              # Create an issue on L<GitHub>.\mRequired: L<userid|/userid>, L<repository|/repository>, L<body|/body>, L<title|/title>.\mIf the operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the issue was created successfully else false.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat    = $gitHub->patKey(1);
  my $user   = qm $gitHub->userid;     $user   or confess "userid required";
  my $repo   = qm $gitHub->repository; $repo   or confess "repository required";
  my $body   =    $gitHub->body;       $body   or confess "body required";
  my $title  =    $gitHub->title;      $title  or confess "title required";
  my $bran   = qm $gitHub->refOrBranch(0);
  my $url    = url;

  my $json   = encodeJson({body=>$body,  title=>$title});                       # Issue in json
  owf(my $tmpFile = temporaryFile(), $json);                                    # Write issue definition
  my $d = q( -d @).$tmpFile;
  my $u = filePath($url, $user, $repo, qw(issues));
  my $s = "curl -si -X POST $pat $u $d";                                        # Create url
  my $r = GitHub::Crud::Response::new($gitHub, $s);
  my $success = $r->status == 201;                                              # Check response code
  unlink $tmpFile;                                                              # Cleanup
  $gitHub->failed = $success ? undef : 1;
  !$success and $gitHub->confessOnFailure and                                   # Confess to any failure if so requested
    confess join "\n", dump($gitHub), $json, $s;
  $success ? 1 : undef                                                          # Return true on success
 }

sub createIssueFromSavedToken($$$$;$)                                           # Create an issue on L<GitHub> using an access token as supplied or saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.\mReturns true if the issue was created successfully else false.
 {my ($userid, $repository, $title, $body, $accessFolderOrToken) = @_;          # Userid on GitHub, repository name, issue title, issue body, location of access token.
  my $g = GitHub::Crud::new;
  $g->userid                    = $userid;
  $g->repository                = $repository;
  $g->title                     = $title;
  $g->body                      = $body;
  $g->personalAccessTokenFolder = $accessFolderOrToken;
  $g->loadPersonalAccessToken;
  $g->confessOnFailure          = 1;
  $g->createIssue;
 }

sub currentRepo()                                                               # Create a github object for the  current repo if we are on github actions
 {if (my $r = $ENV{GITHUB_REPOSITORY})                                          # We are on GitHub
   {my ($user, $repo) = split m(/), $r, 2;
    my $g = GitHub::Crud::new;
    $g->userid                    = $user;
    $g->repository                = $repo;
    $g->personalAccessToken       = $ENV{GITHUB_TOKEN};
    $g->confessOnFailure          = 1;

    if (!$g->personalAccessToken)
     {confess "Unable to load github token for repository $r from environment variable: GITHUB_TOKEN\nSee: https://github.com/philiprbrenan/postgres/blob/main/.github/workflows/main.yml";
     }

    return $g;
   }
  undef
 }

sub createIssueInCurrentRepo($$)                                                # Create an issue in the current GitHub repo if we are running on GitHub
 {my ($title, $body) = @_;                                                      # Title of issue, body of issue
  if (my $g = currentRepo)                                                      # We are on GitHub
   {$g->title                     = $title;
    $g->body                      = $body;
    $g->createIssue;
   }
 }

sub writeFileUsingSavedToken($$$$;$)                                            # Write to a file on L<GitHub> using a personal access token as supplied or saved in a file. Return B<1> on success or confess to any failure.
 {my ($userid, $repository, $file, $content, $accessFolderOrToken) = @_;        # Userid on GitHub, repository name, file name on github, file content, location of access token.
  my $g = GitHub::Crud::new;
  $g->userid     = $userid;     $userid     or confess "Userid required";
  $g->repository = $repository; $repository or confess "Repository required";
  $g->gitFile    = $file;       $file       or confess "File required";
  $g->personalAccessTokenFolder = $accessFolderOrToken;
  $g->loadPersonalAccessToken;
  $g->write($content);
 }

sub writeFileFromFileUsingSavedToken($$$$;$)                                    # Copy a file to L<github>  using a personal access token as supplied or saved in a file. Return B<1> on success or confess to any failure.
 {my ($userid, $repository, $file, $localFile, $accessFolderOrToken) = @_;      # Userid on GitHub, repository name, file name on github, file content, location of access token.
  writeFileUsingSavedToken($userid, $repository, $file,
                           readBinaryFile($localFile), $accessFolderOrToken);
 }

sub writeFileFromCurrentRun($$)                                                 # Write to a file into the repository from the current run
 {my ($target, $text) = @_;                                                     # The target file name in the repo, the text to write into this file
  if (my $g = currentRepo)                                                      # We are on GitHub
   {$g->gitFile = $target;
    $g->write($text);
   }
 }

sub writeFileFromFileFromCurrentRun($)                                          # Write a file into the repository from the current run
 {my ($target) = @_;                                                            # File name both locally and in the repo
  -e $target or confess "File to upload does not exist:\n$target";
  if (my $g = currentRepo)                                                      # We are on GitHub
   {$g->gitFile = $target;
    $g->write(scalar(readFile($target)));
   }
 }

sub writeBinaryFileFromFileInCurrentRun($$)                                     # Upload a binary file from the current run into the repo.
 {my ($target, $source) = @_;                                                   # The target file name in the repo, the current file name in the run
  if (my $g = currentRepo)                                                      # We are on GitHub
   {$g->gitFile = $target;
    $g->write(readBinaryFile($source));
   }
 }

sub readFileUsingSavedToken($$$;$)                                              # Read from a file on L<GitHub> using a personal access token as supplied or saved in a file.  Return the content of the file on success or confess to any failure.
 {my ($userid, $repository, $file, $accessFolderOrToken) = @_;                  # Userid on GitHub, repository name, file name on github, location of access token.
  my $g = GitHub::Crud::new;
  $g->userid                    = $userid;
  $g->repository                = $repository;
  $g->gitFile                   = $file;
  $g->personalAccessTokenFolder = $accessFolderOrToken;
  $g->loadPersonalAccessToken;
  $g->read;
 }

sub writeFolderUsingSavedToken($$$$;$)                                          # Write all the files in a local folder to a target folder on a named L<GitHub> repository using a personal access token as supplied or saved in a file.
 {my ($userid,$repository,$targetFolder,$localFolder,$accessFolderOrToken) = @_;# Userid on GitHub, repository name, target folder on github, local folder name, location of access token.
  my $g = GitHub::Crud::new;
  $g->userid                    = $userid;
  $g->repository                = $repository;
  $g->personalAccessTokenFolder = $accessFolderOrToken;
  $g->loadPersonalAccessToken;

  for my $file(searchDirectoryTreesForMatchingFiles($localFolder))
   {$g->gitFile = swapFilePrefix($file, $localFolder, $targetFolder);
    $g->write(readBinaryFile($file));
   }
 }

sub writeCommitUsingSavedToken($$$;$)                                           # Write all the files in a local folder to a named L<GitHub> repository using a personal access token as supplied or saved in a file.
 {my ($userid, $repository, $source, $accessFolderOrToken) = @_;                # Userid on GitHub, repository name, local folder on github, optionally: location of access token.
  my $g = GitHub::Crud::new;
  $g->userid                    = $userid;
  $g->repository                = $repository;
  $g->personalAccessTokenFolder = $accessFolderOrToken;
  $g->loadPersonalAccessToken;
  $g->branch                    = 'master';

  $g->writeCommit($source);
 }

sub deleteFileUsingSavedToken($$$;$)                                            # Delete a file on GitHub using a saved token
 {my ($userid, $repository, $target, $accessFolderOrToken) = @_;                # Userid on GitHub, repository name, file on Github, optional: the folder containing saved access tokens
  my $g = GitHub::Crud::new;
  $g->userid                    = $userid;
  $g->repository                = $repository;
  $g->personalAccessTokenFolder = $accessFolderOrToken;
  $g->loadPersonalAccessToken;

  $g->gitFile = $target;
  $g->delete;
 }

sub getRepositoryUsingSavedToken($$;$)                                          # Get repository details using a saved token
 {my ($userid, $repository, $accessFolderOrToken) = @_;                         # Userid on GitHub, repository name, optionally: location of access token.
  my $g = GitHub::Crud::new;
  $g->userid     = $userid;     $userid     or confess "Userid required";
  $g->repository = $repository; $repository or confess "Repository required";
  $g->personalAccessTokenFolder = $accessFolderOrToken;
  $g->loadPersonalAccessToken;
  $g->getRepository;
 }

sub getRepositoryUpdatedAtUsingSavedToken($$;$)                                 # Get repository 'updated_at' using a saved token and return the time in number of seconds since the Unix epoch.
 {my ($userid, $repository, $accessFolderOrToken) = @_;                         # Userid on GitHub, repository name, optionally: location of access token.
  my $r = &getRepositoryUsingSavedToken(@_);                                    # Get repository details using a saved token
  my $u = $r->data->{updated_at};
  return Date::Manip::UnixDate($u,'%s');
 }

#D1 Access tokens                                                               # Load and save access tokens. Some L<github> requets must be signed with an L<OAuth>  access token. These methods allow you to store and reuse such tokens.

sub savePersonalAccessToken($)                                                  # Save a L<GitHub> personal access token by userid in folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $user = qm $gitHub->userid;           $user or confess "userid required";
  my $pat  = $gitHub->personalAccessToken; $pat  or confess "personal access token required";
  my $dir  = $gitHub->personalAccessTokenFolder // accessFolder;
  my $file = filePathExt($dir, $user, q(data));
  makePath($file);
  storeFile($file, {pat=>$pat});                                                # Store personal access token
  -e $file or confess "Unable to store personal access token in file:\n$file";  # Complain if store fails
  my $p = retrieveFile $file;                                                   # Retrieve access token to check that we wrote it successfully
  $pat eq $p->{pat} or                                                          # Check file format
    confess "File contains the wrong personal access token:\n$file";
 }

sub loadPersonalAccessToken($)                                                  # Load a personal access token by userid from folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $user = qm $gitHub->userid; $user or confess "userid required";

  if (length($gitHub->personalAccessTokenFolder//accessFolder) == 43)           # Access token supplied directly
   {return $gitHub->personalAccessToken = $gitHub->personalAccessTokenFolder;
   }

  if ($ENV{GITHUB_TOKEN})                                                       # Access token supplied through environment
   {return $gitHub->personalAccessToken = $ENV{GITHUB_TOKEN};
   }

  my $dir  = $gitHub->personalAccessTokenFolder // accessFolder;
  my $file = filePathExt($dir, $user, q(data));
  my $p = retrieveFile $file;                                                   # Load personal access token
  my $a = $p->{pat} or                                                          # Check file format
    confess "File does not contain a personal access token:\n$file";
  $gitHub->personalAccessToken = $a;                                            # Retrieve token
 }

#D0
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# containingFolder

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
createIssueFromSavedToken
createIssueInCurrentRepo
createRepositoryFromSavedToken
deleteFileUsingSavedToken
getRepository
getRepositoryUsingSavedToken
getRepositoryUpdatedAtUsingSavedToken
readFileUsingSavedToken
writeBinaryFileFromFileInCurrentRun
writeCommitUsingSavedToken
writeFileFromCurrentRun
writeFileFromFileUsingSavedToken
writeFileUsingSavedToken
writeFolderUsingSavedToken
);
%EXPORT_TAGS  = (all=>[@EXPORT_OK]);

#podDocumentation

=pod

=encoding utf-8

=head1 Name

GitHub::Crud - Create, Read, Update, Delete files, commits, issues, and web hooks on GitHub.

=head1 Synopsis

Create, Read, Update, Delete files, commits, issues, and web hooks on GitHub as
described at:

  https://developer.github.com/v3/repos/contents/#update-a-file

Commit a folder to GitHub then read and check some of the uploaded content:

  use GitHub::Crud;
  use Data::Table::Text qw(:all);

  my $f  = temporaryFolder;                                                     # Folder in which we will create some files to upload in the commit
  my $c  = dateTimeStamp;                                                       # Create some content
  my $if = q(/home/phil/.face);                                                 # Image file

  writeFile(fpe($f, q(data), $_, qw(txt)), $c) for 1..3;                        # Place content in files in a sub folder
  copyBinaryFile $if, my $If = fpe $f, qw(face jpg);                            # Add an image

  my $g = GitHub::Crud::new                                                     # Create GitHub
    (userid           => q(philiprbrenan),
     repository       => q(aaa),
     branch           => q(test),
     confessOnFailure => 1);

  $g->loadPersonalAccessToken;                                                  # Load a personal access token
  $g->writeCommit($f);                                                          # Upload commit - confess to any errors

  my $C = $g->read(q(data/1.txt));                                              # Read data written in commit
  my $I = $g->read(q(face.jpg));
  my $i = readBinaryFile $if;

  confess "Date stamp failed" unless $C eq $c;                                  # Check text
  confess "Image failed"      unless $i eq $I;                                  # Check image
  confess "Write commit succeeded";

=head1 Prerequisites

 sudo apt-get install curl

=head1 Description

Create, Read, Update, Delete files, commits, issues, and web hooks on GitHub.


Version 20210211.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Constructor

Create a L<GitHub|https://github.com/philiprbrenan> object with the specified attributes describing the interface with L<GitHub|https://github.com/philiprbrenan>.

=head2 new(%attributes)

Create a new L<GitHub|https://github.com/philiprbrenan> object with attributes as described at: L<GitHub::Crud Definition>.

     Parameter    Description
  1  %attributes  Attribute values

B<Example:>


    my $f  = temporaryFolder;                                                     # Folder in which we will create some files to upload in the commit
    my $c  = dateTimeStamp;                                                       # Create some content
    my $if = q(/home/phil/.face);                                                 # Image file

    writeFile(fpe($f, q(data), $_, qw(txt)), $c) for 1..3;                        # Place content in files in a sub folder
    copyBinaryFile $if, my $If = fpe $f, qw(face jpg);                            # Add an image


    my $g = GitHub::Crud::new                                                     # Create GitHub  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      (userid           => q(philiprbrenan),
       repository       => q(aaa),
       branch           => q(test),
       confessOnFailure => 1);

    $g->loadPersonalAccessToken;                                                  # Load a personal access token
    $g->writeCommit($f);                                                          # Upload commit - confess to any errors

    my $C = $g->read(q(data/1.txt));                                              # Read data written in commit
    my $I = $g->read(q(face.jpg));
    my $i = readBinaryFile $if;

    confess "Date stamp failed" unless $C eq $c;                                  # Check text
    confess "Image failed"      unless $i eq $I;                                  # Check image
    success "Write commit succeeded";


=head1 Files

File actions on the contents of L<GitHub|https://github.com/philiprbrenan> repositories.

=head2 list($gitHub)

List all the files contained in a L<GitHub|https://github.com/philiprbrenan> repository or all the files below a specified folder in the repository.

Required attributes: L<userid|/userid>, L<repository|/repository>.

Optional attributes: L<gitFolder|/gitFolder>, L<refOrBranch|/refOrBranch>, L<nonRecursive|/nonRecursive>, L<patKey|/patKey>.

Use the L<gitFolder|/gitFolder> parameter to specify the folder to start the list from, by default, the listing will start at the root folder of your repository.

Use the L<nonRecursive|/nonRecursive> option if you require only the files in the start folder as otherwise all the folders in the start folder will be listed as well which might take some time.

If the list operation is successful, L<failed|/failed> is set to false and L<fileList|/fileList> is set to refer to an array of the file names found.

If the list operation fails then L<failed|/failed> is set to true and L<fileList|/fileList> is set to refer to an empty array.

Returns the list of file names found or empty list if no files were found.

     Parameter  Description
  1  $gitHub    GitHub

B<Example:>



    success "list:", gitHub->list;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


  # list: alpha.data .github/workflows/test.yaml images/aaa.txt images/aaa/bbb.txt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 specialFileData($d)

Do not encode or decode data with a known file signature

     Parameter  Description
  1  $d         String to check

=head2 read($gitHub, $File)

Read data from a file on L<GitHub|https://github.com/philiprbrenan>.

Required attributes: L<userid|/userid>, L<repository|/repository>.

Optional attributes: L<gitFile|/gitFile> = the file to read, L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.

If the read operation is successful, L<failed|/failed> is set to false and L<readData|/readData> is set to the data read from the file.

If the read operation fails then L<failed|/failed> is set to true and L<readData|/readData> is set to B<undef>.

Returns the data read or B<undef> if no file was found.

     Parameter  Description
  1  $gitHub    GitHub
  2  $File      File o read if not specified in gitFile

B<Example:>


    my $g = gitHub;
    $g->gitFile = my $f = q(z'2  'z"z.data);
    my $d = q(𝝰𝝱𝝲);
    $g->write($d);

    confess "read FAILED" unless $g->read eq $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Read passed";


=head2 write($gitHub, $data, $File)

Write utf8 data into a L<GitHub|https://github.com/philiprbrenan> file.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>. Either specify the target file on:<github> using the L<gitFile|/gitFile> attribute or supply it as the third parameter.  Returns B<true> on success else L<undef|https://perldoc.perl.org/functions/undef.html>.

     Parameter  Description
  1  $gitHub    GitHub object
  2  $data      Data to be written
  3  $File      Optionally the name of the file on github

B<Example:>


    my $g = gitHub;
    $g->gitFile = "zzz.data";

    my $d = dateTimeStamp.q( 𝝰𝝱𝝲);

    if (1)
     {my $t = time();

      $g->write($d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      lll "First write time: ", time() -  $t;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }

    my $r = $g->read;
    lll "Write bbb: $r";
    if (1)
     {my $t = time();

      $g->write($d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      lll "Second write time: ", time() -  $t;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }

    confess "write FAILED" unless $g->exists;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Write passed";


=head2 readBlob($gitHub, $sha)

Read a L<blob|https://en.wikipedia.org/wiki/Binary_large_object> from L<GitHub|https://github.com/philiprbrenan>.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>. Returns the content of the L<blob|https://en.wikipedia.org/wiki/Binary_large_object> identified by the specified L<SHA|https://en.wikipedia.org/wiki/SHA-1>.

     Parameter  Description
  1  $gitHub    GitHub object
  2  $sha       Data to be written

B<Example:>


    my $g = gitHub;
    $g->gitFile = "face.jpg";
    my $d = readBinaryFile(q(/home/phil/.face));
    my $s = $g->writeBlob($d);
    my $S = q(4a2df549febb701ba651aae46e041923e9550cb8);
    confess q(Write blob FAILED) unless $s eq $S;


    my $D = $g->readBlob($s);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    confess q(Write/Read blob FAILED) unless $d eq $D;
    success q(Write/Read blob passed);


=head2 writeBlob($gitHub, $data)

Write data into a L<GitHub|https://github.com/philiprbrenan> as a L<blob|https://en.wikipedia.org/wiki/Binary_large_object> that can be referenced by future commits.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>. Returns the L<SHA|https://en.wikipedia.org/wiki/SHA-1> of the created L<blob|https://en.wikipedia.org/wiki/Binary_large_object> or L<undef|https://perldoc.perl.org/functions/undef.html> in a failure occurred.

     Parameter  Description
  1  $gitHub    GitHub object
  2  $data      Data to be written

B<Example:>


    my $g = gitHub;
    $g->gitFile = "face.jpg";
    my $d = readBinaryFile(q(/home/phil/.face));

    my $s = $g->writeBlob($d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my $S = q(4a2df549febb701ba651aae46e041923e9550cb8);
    confess q(Write blob FAILED) unless $s eq $S;

    my $D = $g->readBlob($s);
    confess q(Write/Read blob FAILED) unless $d eq $D;
    success q(Write/Read blob passed);


=head2 copy($gitHub, $target)

Copy a source file from one location to another target location in your L<GitHub|https://github.com/philiprbrenan> repository, overwriting the target file if it already exists.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be copied.

Optional attributes: L<refOrBranch|/refOrBranch>.

If the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.

     Parameter  Description
  1  $gitHub    GitHub object
  2  $target    The name of the file to be created

B<Example:>


    my ($f1, $f2) = ("zzz.data", "zzz2.data");
    my $g = gitHub;
    $g->gitFile   = $f2; $g->delete;
    $g->gitFile   = $f1;
    my $d = dateTimeStamp;
    my $w = $g->write($d);

    my $r = $g->copy($f2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    lll "Copy created: $r";
    $g->gitFile   = $f2;
    my $D = $g->read;
    lll "Read     ccc: $D";

    confess "copy FAILED" unless $d eq $D;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Copy passed"


=head2 exists($gitHub)

Test whether a file exists on L<GitHub|https://github.com/philiprbrenan> or not and returns an object including the B<sha> and B<size> fields if it does else L<undef|https://perldoc.perl.org/functions/undef.html>.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> file to test.

Optional attributes: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>


    my $g = gitHub;
    $g->gitFile    = "test4.html";
    my $d = dateTimeStamp;
    $g->write($d);

    confess "exists FAILED" unless $g->read eq $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $g->delete;

    confess "exists FAILED" if $g->read eq $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Exists passed";


=head2 rename($gitHub, $target)

Rename a source file on L<GitHub|https://github.com/philiprbrenan> if the target file name is not already in use.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be renamed.

Optional attributes: L<refOrBranch|/refOrBranch>.

Returns the new name of the file B<renamed> if the rename was successful else B<undef> if the rename failed.

     Parameter  Description
  1  $gitHub    GitHub object
  2  $target    The new name of the file

B<Example:>


    my ($f1, $f2) = qw(zzz.data zzz2.data);
    my $g = gitHub;
       $g->gitFile = $f2; $g->delete;

    my $d = dateTimeStamp;
    $g->gitFile  = $f1;
    $g->write($d);

    confess "rename FAILED" unless $g->read eq $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    $g->rename($f2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    confess "rename FAILED" if $g->exists;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $g->gitFile  = $f2;

    confess "rename FAILED" if $g->read eq $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Rename passed";


=head2 delete($gitHub)

Delete a file from L<GitHub|https://github.com/philiprbrenan>.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be deleted.

Optional attributes: L<refOrBranch|/refOrBranch>.

If the delete operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the delete was successful else false.

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>


    my $g = gitHub;
    my $d = dateTimeStamp;
    $g->gitFile = "zzz.data";
    $g->write($d);


    confess "delete FAILED" unless $g->read eq $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    if (1)
     {my $t = time();

      my $d = $g->delete;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      lll "Delete   1: ", $d;

      lll "First delete: ", time() -  $t;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      confess "delete FAILED" if $g->exists;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }

    if (1)
     {my $t = time();

      my $d = $g->delete;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      lll "Delete   1: ", $d;

      lll "Second delete: ", time() -  $t;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      confess "delete FAILED" if $g->exists;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    success "Delete passed";


=head1 Repositories

Perform actions on L<GitHub|https://github.com/philiprbrenan> repositories.

=head2 getRepository($gitHub)

Get the overall details of a repository

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>



    my $r = gitHub(repository => q(C))->getRepository;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Get repository succeeded";


=head2 listCommits($gitHub)

List all the commits in a L<GitHub|https://github.com/philiprbrenan> repository.

Required attributes: L<userid|/userid>, L<repository|/repository>.

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>



    my $c = gitHub->listCommits;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my %s = listCommitShas $c;
    lll "Commits
",     dump $c;
    lll "Commit shas
", dump \%s;
    success "ListCommits passed";


=head2 listCommitShas($commits)

Create {commit name => sha} from the results of L<listCommits>.

     Parameter  Description
  1  $commits   Commits from L<listCommits>

B<Example:>


    my $c = gitHub->listCommits;

    my %s = listCommitShas $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    lll "Commits
",     dump $c;
    lll "Commit shas
", dump \%s;
    success "ListCommits passed";


=head2 writeCommit($gitHub, $folder, @files)

Write all the files in a B<$folder> (or just the the named files) into a L<GitHub|https://github.com/philiprbrenan> repository in parallel as a commit on the specified branch.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<refOrBranch|/refOrBranch>.

     Parameter  Description
  1  $gitHub    GitHub object
  2  $folder    File prefix to remove
  3  @files     Files to write

B<Example:>


    my $f  = temporaryFolder;                                                     # Folder in which we will create some files to upload in the commit
    my $c  = dateTimeStamp;                                                       # Create some content
    my $if = q(/home/phil/.face);                                                 # Image file

    writeFile(fpe($f, q(data), $_, qw(txt)), $c) for 1..3;                        # Place content in files in a sub folder
    copyBinaryFile $if, my $If = fpe $f, qw(face jpg);                            # Add an image

    my $g = GitHub::Crud::new                                                     # Create GitHub
      (userid           => q(philiprbrenan),
       repository       => q(aaa),
       branch           => q(test),
       confessOnFailure => 1);

    $g->loadPersonalAccessToken;                                                  # Load a personal access token

    $g->writeCommit($f);                                                          # Upload commit - confess to any errors  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my $C = $g->read(q(data/1.txt));                                              # Read data written in commit
    my $I = $g->read(q(face.jpg));
    my $i = readBinaryFile $if;

    confess "Date stamp failed" unless $C eq $c;                                  # Check text
    confess "Image failed"      unless $i eq $I;                                  # Check image
    success "Write commit succeeded";


=head2 listWebHooks($gitHub)

List web hooks associated with your L<GitHub|https://github.com/philiprbrenan> repository.

Required: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>.

If the list operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the list  operation was successful else false.

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>



    success join ' ', q(Webhooks:), dump(gitHub->listWebHooks);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 createPushWebHook($gitHub)

Create a web hook for your L<GitHub|https://github.com/philiprbrenan> userid.

Required: L<userid|/userid>, L<repository|/repository>, L<url|/url>, L<patKey|/patKey>.

Optional: L<secret|/secret>.

If the create operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the web hook was created successfully else false.

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>


    my $g = gitHub;

    my $d = $g->createPushWebHook;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success join ' ', "Create web hook:", dump($d);


=head2 listRepositories($gitHub)

List the repositories accessible to a user on L<GitHub|https://github.com/philiprbrenan>.

Required: L<userid|/userid>.

Returns details of the repositories.

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>



    success "List repositories: ", dump(gitHub()->listRepositories);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 createRepository($gitHub)

Create a repository on L<GitHub|https://github.com/philiprbrenan>.

Required: L<userid|/userid>, L<repository|/repository>.

Returns true if the issue was created successfully else false.

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>



    gitHub(repository => q(ccc))->createRepository;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Create repository succeeded";


=head2 createRepositoryFromSavedToken($userid, $repository, $private, $accessFolderOrToken)

Create a repository on L<GitHub|https://github.com/philiprbrenan> using an access token either as supplied or saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.

Returns true if the issue was created successfully else false.

     Parameter             Description
  1  $userid               Userid on GitHub
  2  $repository           The repository name
  3  $private              True if the repo is private
  4  $accessFolderOrToken  Location of access token.

B<Example:>



    createRepositoryFromSavedToken(q(philiprbrenan), q(ddd));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Create repository succeeded";


=head2 createIssue($gitHub)

Create an issue on L<GitHub|https://github.com/philiprbrenan>.

Required: L<userid|/userid>, L<repository|/repository>, L<body|/body>, L<title|/title>.

If the operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the issue was created successfully else false.

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>



    gitHub(title=>q(Hello), body=>q(World))->createIssue;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Create issue succeeded";


=head2 createIssueFromSavedToken($userid, $repository, $title, $body, $accessFolderOrToken)

Create an issue on L<GitHub|https://github.com/philiprbrenan> using an access token as supplied or saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.

Returns true if the issue was created successfully else false.

     Parameter             Description
  1  $userid               Userid on GitHub
  2  $repository           Repository name
  3  $title                Issue title
  4  $body                 Issue body
  5  $accessFolderOrToken  Location of access token.

B<Example:>



    &createIssueFromSavedToken(qw(philiprbrenan ddd hello World));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Create issue succeeded";


=head2 currentRepo()

Create a github object for the  current repo if we are on github actions


=head2 createIssueInCurrentRepo($title, $body)

Create an issue in the current GitHub repo if we are running on GitHub

     Parameter  Description
  1  $title     Title of issue
  2  $body      Body of issue

=head2 writeFileUsingSavedToken($userid, $repository, $file, $content, $accessFolderOrToken)

Write to a file on L<GitHub|https://github.com/philiprbrenan> using a personal access token as supplied or saved in a file. Return B<1> on success or confess to any failure.

     Parameter             Description
  1  $userid               Userid on GitHub
  2  $repository           Repository name
  3  $file                 File name on github
  4  $content              File content
  5  $accessFolderOrToken  Location of access token.

B<Example:>


    my $s = q(HelloWorld);

    &writeFileUsingSavedToken(qw(philiprbrenan ddd hello.txt), $s);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my $S = gitHub(repository=>q(ddd), gitFile=>q(hello.txt))->read;

    confess "Write file using saved token FAILED" unless $s eq $S;
    success "Write file using saved token succeeded";


=head2 writeFileFromFileUsingSavedToken($userid, $repository, $file, $localFile, $accessFolderOrToken)

Copy a file to L<GitHub|https://github.com/philiprbrenan>  using a personal access token as supplied or saved in a file. Return B<1> on success or confess to any failure.

     Parameter             Description
  1  $userid               Userid on GitHub
  2  $repository           Repository name
  3  $file                 File name on github
  4  $localFile            File content
  5  $accessFolderOrToken  Location of access token.

B<Example:>


    my $f = writeFile(undef, my $s = "World
");

    &writeFileFromFileUsingSavedToken(qw(philiprbrenan ddd hello.txt), $f);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my $S = gitHub(repository=>q(ddd), gitFile=>q(hello.txt))->read;
    confess "Write file from file using saved token FAILED" unless $s eq $S;
    success "Write file from file using saved token succeeded"


=head2 writeFileFromCurrentRun($target, $text)

Write to a file into the repository from the current run

     Parameter  Description
  1  $target    The target file name in the repo
  2  $text      The text to write into this file

=head2 writeFileFromFileFromCurrentRun($target)

Write a file into the repository from the current run

     Parameter  Description
  1  $target    File name both locally and in the repo

=head2 writeBinaryFileFromFileInCurrentRun($target, $source)

Upload a binary file from the current run into the repo.

     Parameter  Description
  1  $target    The target file name in the repo
  2  $source    The current file name in the run

=head2 readFileUsingSavedToken($userid, $repository, $file, $accessFolderOrToken)

Read from a file on L<GitHub|https://github.com/philiprbrenan> using a personal access token as supplied or saved in a file.  Return the content of the file on success or confess to any failure.

     Parameter             Description
  1  $userid               Userid on GitHub
  2  $repository           Repository name
  3  $file                 File name on github
  4  $accessFolderOrToken  Location of access token.

B<Example:>


    my $s = q(Hello to the World);
            &writeFileUsingSavedToken(qw(philiprbrenan ddd hello.txt), $s);

    my $S = &readFileUsingSavedToken (qw(philiprbrenan ddd hello.txt));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    confess "Read file using saved token FAILED" unless $s eq $S;
    success "Read file using saved token succeeded"


=head2 writeFolderUsingSavedToken($userid, $repository, $targetFolder, $localFolder, $accessFolderOrToken)

Write all the files in a local folder to a target folder on a named L<GitHub|https://github.com/philiprbrenan> repository using a personal access token as supplied or saved in a file.

     Parameter             Description
  1  $userid               Userid on GitHub
  2  $repository           Repository name
  3  $targetFolder         Target folder on github
  4  $localFolder          Local folder name
  5  $accessFolderOrToken  Location of access token.

=head2 writeCommitUsingSavedToken($userid, $repository, $source, $accessFolderOrToken)

Write all the files in a local folder to a named L<GitHub|https://github.com/philiprbrenan> repository using a personal access token as supplied or saved in a file.

     Parameter             Description
  1  $userid               Userid on GitHub
  2  $repository           Repository name
  3  $source               Local folder on github
  4  $accessFolderOrToken  Optionally: location of access token.

=head2 deleteFileUsingSavedToken($userid, $repository, $target, $accessFolderOrToken)

Delete a file on GitHub using a saved token

     Parameter             Description
  1  $userid               Userid on GitHub
  2  $repository           Repository name
  3  $target               File on Github
  4  $accessFolderOrToken  Optional: the folder containing saved access tokens

=head2 getRepositoryUsingSavedToken($userid, $repository, $accessFolderOrToken)

Get repository details using a saved token

     Parameter             Description
  1  $userid               Userid on GitHub
  2  $repository           Repository name
  3  $accessFolderOrToken  Optionally: location of access token.

B<Example:>



    my $r = getRepositoryUsingSavedToken(q(philiprbrenan), q(aaa));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Get repository using saved access token succeeded";


=head2 getRepositoryUpdatedAtUsingSavedToken($userid, $repository, $accessFolderOrToken)

Get repository 'updated_at' using a saved token and return the time in number of seconds since the Unix epoch.

     Parameter             Description
  1  $userid               Userid on GitHub
  2  $repository           Repository name
  3  $accessFolderOrToken  Optionally: location of access token.

B<Example:>



    my $u = getRepositoryUpdatedAtUsingSavedToken(q(philiprbrenan), q(aaa));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    success "Get repository updated_at field succeeded";


=head1 Access tokens

Load and save access tokens. Some L<GitHub|https://github.com/philiprbrenan> requets must be signed with an L<Oauth|https://en.wikipedia.org/wiki/OAuth>  access token. These methods allow you to store and reuse such tokens.

=head2 savePersonalAccessToken($gitHub)

Save a L<GitHub|https://github.com/philiprbrenan> personal access token by userid in folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>


    my $d = temporaryFolder;
    my $t = join '', 1..20;

    my $g = gitHub
     (userid                    => q(philiprbrenan),
      personalAccessToken       => $t,
      personalAccessTokenFolder => $d,
     );


            $g->savePersonalAccessToken;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my $T = $g->loadPersonalAccessToken;

    confess "Load/Save token FAILED" unless $t eq $T;
    success "Load/Save token succeeded"


=head2 loadPersonalAccessToken($gitHub)

Load a personal access token by userid from folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.

     Parameter  Description
  1  $gitHub    GitHub object

B<Example:>


    my $d = temporaryFolder;
    my $t = join '', 1..20;

    my $g = gitHub
     (userid                    => q(philiprbrenan),
      personalAccessToken       => $t,
      personalAccessTokenFolder => $d,
     );

            $g->savePersonalAccessToken;

    my $T = $g->loadPersonalAccessToken;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    confess "Load/Save token FAILED" unless $t eq $T;
    success "Load/Save token succeeded"



=head2 GitHub::Crud Definition


Attributes describing the interface with L<GitHub|https://github.com/philiprbrenan>.




=head3 Input fields


=head4 body

The body of an issue.

=head4 branch

Branch name (you should create this branch first) or omit it for the default branch which is usually 'master'.

=head4 confessOnFailure

Confess to any failures

=head4 gitFile

File name on L<GitHub|https://github.com/philiprbrenan> - this name can contain '/'. This is the file to be read from, written to, copied from, checked for existence or deleted.

=head4 gitFolder

Folder name on L<GitHub|https://github.com/philiprbrenan> - this name can contain '/'.

=head4 message

Optional commit message

=head4 nonRecursive

Fetch only one level of files with L<list|https://en.wikipedia.org/wiki/Linked_list>.

=head4 personalAccessToken

A personal access token with scope "public_repo" as generated on page: https://github.com/settings/tokens.

=head4 personalAccessTokenFolder

The folder into which to save personal access tokens. Set to q(/etc/GitHubCrudPersonalAccessToken) by default.

=head4 private

Whether the repository being created should be private or not.

=head4 repository

The name of the repository to be worked on minus the userid - you should create this repository first manually.

=head4 secret

The secret for a web hook - this is created by the creator of the web hook and remembered by L<GitHub|https://github.com/philiprbrenan>,

=head4 title

The title of an issue.

=head4 userid

Userid on L<GitHub|https://github.com/philiprbrenan> of the repository to be worked on.

=head4 webHookUrl

The url for a web hook.



=head3 Output fields


=head4 failed

Defined if the last request to L<GitHub|https://github.com/philiprbrenan> failed else B<undef>.

=head4 fileList

Reference to an array of files produced by L<list|/list>.

=head4 readData

Data produced by L<read|/read>.

=head4 response

A reference to L<GitHub|https://github.com/philiprbrenan>'s response to the latest request.



=head2 GitHub::Crud::Response Definition


Attributes describing a response from L<GitHub|https://github.com/philiprbrenan>.




=head3 Output fields


=head4 content

The actual content of the file from L<GitHub|https://github.com/philiprbrenan>.

=head4 data

The data received from L<GitHub|https://github.com/philiprbrenan>, normally in L<Json|https://en.wikipedia.org/wiki/JSON> format.

=head4 status

Our version of Status.



=head1 Index


1 L<copy|/copy> - Copy a source file from one location to another target location in your L<GitHub|https://github.com/philiprbrenan> repository, overwriting the target file if it already exists.

2 L<createIssue|/createIssue> - Create an issue on L<GitHub|https://github.com/philiprbrenan>.

3 L<createIssueFromSavedToken|/createIssueFromSavedToken> - Create an issue on L<GitHub|https://github.com/philiprbrenan> using an access token as supplied or saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.

4 L<createIssueInCurrentRepo|/createIssueInCurrentRepo> - Create an issue in the current GitHub repo if we are running on GitHub

5 L<createPushWebHook|/createPushWebHook> - Create a web hook for your L<GitHub|https://github.com/philiprbrenan> userid.

6 L<createRepository|/createRepository> - Create a repository on L<GitHub|https://github.com/philiprbrenan>.

7 L<createRepositoryFromSavedToken|/createRepositoryFromSavedToken> - Create a repository on L<GitHub|https://github.com/philiprbrenan> using an access token either as supplied or saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.

8 L<currentRepo|/currentRepo> - Create a github object for the  current repo if we are on github actions

9 L<delete|/delete> - Delete a file from L<GitHub|https://github.com/philiprbrenan>.

10 L<deleteFileUsingSavedToken|/deleteFileUsingSavedToken> - Delete a file on GitHub using a saved token

11 L<exists|/exists> - Test whether a file exists on L<GitHub|https://github.com/philiprbrenan> or not and returns an object including the B<sha> and B<size> fields if it does else L<undef|https://perldoc.perl.org/functions/undef.html>.

12 L<getRepository|/getRepository> - Get the overall details of a repository

13 L<getRepositoryUpdatedAtUsingSavedToken|/getRepositoryUpdatedAtUsingSavedToken> - Get repository 'updated_at' using a saved token and return the time in number of seconds since the Unix epoch.

14 L<getRepositoryUsingSavedToken|/getRepositoryUsingSavedToken> - Get repository details using a saved token

15 L<list|/list> - List all the files contained in a L<GitHub|https://github.com/philiprbrenan> repository or all the files below a specified folder in the repository.

16 L<listCommits|/listCommits> - List all the commits in a L<GitHub|https://github.com/philiprbrenan> repository.

17 L<listCommitShas|/listCommitShas> - Create {commit name => sha} from the results of L<listCommits>.

18 L<listRepositories|/listRepositories> - List the repositories accessible to a user on L<GitHub|https://github.com/philiprbrenan>.

19 L<listWebHooks|/listWebHooks> - List web hooks associated with your L<GitHub|https://github.com/philiprbrenan> repository.

20 L<loadPersonalAccessToken|/loadPersonalAccessToken> - Load a personal access token by userid from folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.

21 L<new|/new> - Create a new L<GitHub|https://github.com/philiprbrenan> object with attributes as described at: L<GitHub::Crud Definition>.

22 L<read|/read> - Read data from a file on L<GitHub|https://github.com/philiprbrenan>.

23 L<readBlob|/readBlob> - Read a L<blob|https://en.wikipedia.org/wiki/Binary_large_object> from L<GitHub|https://github.com/philiprbrenan>.

24 L<readFileUsingSavedToken|/readFileUsingSavedToken> - Read from a file on L<GitHub|https://github.com/philiprbrenan> using a personal access token as supplied or saved in a file.

25 L<rename|/rename> - Rename a source file on L<GitHub|https://github.com/philiprbrenan> if the target file name is not already in use.

26 L<savePersonalAccessToken|/savePersonalAccessToken> - Save a L<GitHub|https://github.com/philiprbrenan> personal access token by userid in folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.

27 L<specialFileData|/specialFileData> - Do not encode or decode data with a known file signature

28 L<write|/write> - Write utf8 data into a L<GitHub|https://github.com/philiprbrenan> file.

29 L<writeBinaryFileFromFileInCurrentRun|/writeBinaryFileFromFileInCurrentRun> - Upload a binary file from the current run into the repo.

30 L<writeBlob|/writeBlob> - Write data into a L<GitHub|https://github.com/philiprbrenan> as a L<blob|https://en.wikipedia.org/wiki/Binary_large_object> that can be referenced by future commits.

31 L<writeCommit|/writeCommit> - Write all the files in a B<$folder> (or just the the named files) into a L<GitHub|https://github.com/philiprbrenan> repository in parallel as a commit on the specified branch.

32 L<writeCommitUsingSavedToken|/writeCommitUsingSavedToken> - Write all the files in a local folder to a named L<GitHub|https://github.com/philiprbrenan> repository using a personal access token as supplied or saved in a file.

33 L<writeFileFromCurrentRun|/writeFileFromCurrentRun> - Write to a file into the repository from the current run

34 L<writeFileFromFileFromCurrentRun|/writeFileFromFileFromCurrentRun> - Write a file into the repository from the current run

35 L<writeFileFromFileUsingSavedToken|/writeFileFromFileUsingSavedToken> - Copy a file to L<GitHub|https://github.com/philiprbrenan>  using a personal access token as supplied or saved in a file.

36 L<writeFileUsingSavedToken|/writeFileUsingSavedToken> - Write to a file on L<GitHub|https://github.com/philiprbrenan> using a personal access token as supplied or saved in a file.

37 L<writeFolderUsingSavedToken|/writeFolderUsingSavedToken> - Write all the files in a local folder to a target folder on a named L<GitHub|https://github.com/philiprbrenan> repository using a personal access token as supplied or saved in a file.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install GitHub::Crud

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

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
  1
 }

test unless caller;

1;
#podDocumentation
__DATA__
use Test::More tests => 1;

ok 1;

sub success(@)                                                                  # Write a success message and exit
 {say STDERR join ' ', @_;
# exit;
 }

if (0) {                                                                        #Tread
  my $g = gitHub;
  $g->gitFile = my $f = q(z'2  'z"z.data);
  my $d = q(𝝰𝝱𝝲);
  $g->write($d);
  confess "read FAILED" unless $g->read eq $d;
  success "Read passed";
 }

if (0) {                                                                        #Twrite # The second write should be faster because its L<sha> is known from the read
  my $g = gitHub;
  $g->gitFile = "zzz.data";

  my $d = dateTimeStamp.q( 𝝰𝝱𝝲);

  if (1)
   {my $t = time();
    $g->write($d);
    lll "First write time: ", time() -  $t;
   }

  my $r = $g->read;
  lll "Write bbb: $r";
  if (1)
   {my $t = time();
    $g->write($d);
    lll "Second write time: ", time() -  $t;
   }
  confess "write FAILED" unless $g->exists;
  success "Write passed";
 }

if (0) {                                                                        # Write to and then read from a branch other than master - the branch must already exist in the repo
  my $g = gitHub;
  $g->gitFile = "zzz.data";
  $g->branch  = "aaa";

  $g->delete;
  confess "delete branch FAILED" if $g->exists;

  my $d = dateTimeStamp;
  $g->write($d);
  confess "write branch FAILED" unless $g->read eq $d;
  success "Write branch passed";
 }

if (0) {                                                                        # Write and read a zip file
  my $g = gitHub;
  my $f = temporaryFolder;
  writeFile(fpe($f, $_, q(txt)), $_) for 1..3;
  my $z = fpe($f, qw(z zip));
  say STDERR qx(cd $f; zip $z *);
  $g->gitFile = "z.zip";
  $g->write(readBinaryFile($z), q(z.zip));

  my $F = temporaryFolder;
  my $Z = fpe($F, qw(z zip));
  writeBinaryFile($Z, $g->read);
  my $r = qx(cd $F; unzip $Z);
     $r =~ m(extracting: 3.txt) or confess "Failed to unzip";
  success "Wrote/read a zip file";
 }

if (0) {                                                                        #TreadBlob #TwriteBlob # Write image as blob and read it back
  my $g = gitHub;
  $g->gitFile = "face.jpg";
  my $d = readBinaryFile(q(/home/phil/.face));
  my $s = $g->writeBlob($d);
  my $S = q(4a2df549febb701ba651aae46e041923e9550cb8);
  confess q(Write blob FAILED) unless $s eq $S;

  my $D = $g->readBlob($s);
  confess q(Write/Read blob FAILED) unless $d eq $D;
  success q(Write/Read blob passed);
 }

if (0) {                                                                        #Tcopy
  my ($f1, $f2) = ("zzz.data", "zzz2.data");
  my $g = gitHub;
  $g->gitFile   = $f2; $g->delete;
  $g->gitFile   = $f1;
  my $d = dateTimeStamp;
  my $w = $g->write($d);
  my $r = $g->copy($f2);
  lll "Copy created: $r";
  $g->gitFile   = $f2;
  my $D = $g->read;
  lll "Read     ccc: $D";
  confess "copy FAILED" unless $d eq $D;
  success "Copy passed"
 }

if (0) {                                                                        #Texists
  my $g = gitHub;
  $g->gitFile    = "test4.html";
  my $d = dateTimeStamp;
  $g->write($d);
  confess "exists FAILED" unless $g->read eq $d;
  $g->delete;
  confess "exists FAILED" if $g->read eq $d;
  success "Exists passed";
 }

if (0) {                                                                        #Trename
  my ($f1, $f2) = qw(zzz.data zzz2.data);
  my $g = gitHub;
     $g->gitFile = $f2; $g->delete;

  my $d = dateTimeStamp;
  $g->gitFile  = $f1;
  $g->write($d);
  confess "rename FAILED" unless $g->read eq $d;

  $g->rename($f2);
  confess "rename FAILED" if $g->exists;

  $g->gitFile  = $f2;
  confess "rename FAILED" if $g->read eq $d;
  success "Rename passed";
 }

if (0) {                                                                        #Tdelete # The second delete should be faster because the fact that the file has been deleted is held in the L<sha> cache
  my $g = gitHub;
  my $d = dateTimeStamp;
  $g->gitFile = "zzz.data";
  $g->write($d);

  confess "delete FAILED" unless $g->read eq $d;

  if (1)
   {my $t = time();
    my $d = $g->delete;
    lll "Delete   1: ", $d;
    lll "First delete: ", time() -  $t;
    confess "delete FAILED" if $g->exists;
   }

  if (1)
   {my $t = time();
    my $d = $g->delete;
    lll "Delete   1: ", $d;
    lll "Second delete: ", time() -  $t;
    confess "delete FAILED" if $g->exists;
   }
  success "Delete passed";
 }

if (0)
 {my $g = gitHub;
  $g->gitFile = "testFromAppaApps.html";

  my $d = join '-', 1..9;

  success
    "Write : ", dump($g->write($d)),
    "\nRead 1: ", dump($g->read),
    "\nDelete: ", dump($g->delete),
    "\nRead 2: ", dump($g->read);
 }

if (0) {                                                                        #TlistCommits #TlistCommitShas # List all commits
  my $c = gitHub->listCommits;
  my %s = listCommitShas $c;
  lll "Commits\n",     dump $c;
  lll "Commit shas\n", dump \%s;
  success "ListCommits passed";
 }

if (0) {                                                                        #Tlist
  success "list:", gitHub->list;
# list: alpha.data .github/workflows/test.yaml images/aaa.txt images/aaa/bbb.txt
 }


if (0) {                                                                        #TwriteCommit #Tnew
  my $f  = temporaryFolder;                                                     # Folder in which we will create some files to upload in the commit
  my $c  = dateTimeStamp;                                                       # Create some content
  my $if = q(/home/phil/.face);                                                 # Image file

  writeFile(fpe($f, q(data), $_, qw(txt)), $c) for 1..3;                        # Place content in files in a sub folder
  copyBinaryFile $if, my $If = fpe $f, qw(face jpg);                            # Add an image

  my $g = GitHub::Crud::new                                                     # Create GitHub
    (userid           => q(philiprbrenan),
     repository       => q(aaa),
     branch           => q(test),
     confessOnFailure => 1);

  $g->loadPersonalAccessToken;                                                  # Load a personal access token
  $g->writeCommit($f);                                                          # Upload commit - confess to any errors

  my $C = $g->read(q(data/1.txt));                                              # Read data written in commit
  my $I = $g->read(q(face.jpg));
  my $i = readBinaryFile $if;

  confess "Date stamp failed" unless $C eq $c;                                  # Check text
  confess "Image failed"      unless $i eq $I;                                  # Check image
  success "Write commit succeeded";
 }


if (0) {                                                                        #TcreatePushWebHook
  my $g = gitHub;
  my $d = $g->createPushWebHook;
  success join ' ', "Create web hook:", dump($d);
 }

if (0) {                                                                        #TlistRepositories
  success "List repositories: ", dump(gitHub()->listRepositories);
 }

if (0) {                                                                        #TgetRepository
  my $r = gitHub(repository => q(C))->getRepository;
  success "Get repository succeeded";
 }

if (0) {                                                                        #TgetRepositoryUsingSavedToken
  my $r = getRepositoryUsingSavedToken(q(philiprbrenan), q(aaa));
  success "Get repository using saved access token succeeded";
 }

if (0) {                                                                        #TgetRepositoryUpdatedAtUsingSavedToken
  my $u = getRepositoryUpdatedAtUsingSavedToken(q(philiprbrenan), q(aaa));
  success "Get repository updated_at field succeeded";
 }

if (0) {                                                                        #TcreateRepository
  gitHub(repository => q(ccc))->createRepository;
  success "Create repository succeeded";
 }

if (0) {                                                                        #TlistWebHooks
  success join ' ', q(Webhooks:), dump(gitHub->listWebHooks);
 }

if (0) {                                                                        #TcreateIssue
  gitHub(title=>q(Hello), body=>q(World))->createIssue;
  success "Create issue succeeded";
 }

if (0) {                                                                        #TcreateIssueFromSavedToken
  &createIssueFromSavedToken(qw(philiprbrenan ddd hello World));
  success "Create issue succeeded";
 }

if (0) {                                                                        #TcreateRepositoryFromSavedToken
  createRepositoryFromSavedToken(q(philiprbrenan), q(ddd));
  success "Create repository succeeded";
 }

if (0) {                                                                        #TwriteFileUsingSavedToken
  my $s = q(HelloWorld);
  &writeFileUsingSavedToken(qw(philiprbrenan ddd hello.txt), $s);
  my $S = gitHub(repository=>q(ddd), gitFile=>q(hello.txt))->read;

  confess "Write file using saved token FAILED" unless $s eq $S;
  success "Write file using saved token succeeded";
 }

if (0) {                                                                        #TwriteFileFromFileUsingSavedToken
  my $f = writeFile(undef, my $s = "World\n");
  &writeFileFromFileUsingSavedToken(qw(philiprbrenan ddd hello.txt), $f);
  my $S = gitHub(repository=>q(ddd), gitFile=>q(hello.txt))->read;
  confess "Write file from file using saved token FAILED" unless $s eq $S;
  success "Write file from file using saved token succeeded"
 }

if (0) {                                                                        # Write an empty string to a file to delete it
  my $g = gitHub
   (userid=>q(philiprbrenan), repository=>q(ddd), gitFile=>q(hello.txt));
  my $s = "hello";
  my $f = $g->write($s);
  my $S = $g->read;
  confess "Write.read failed" unless $s eq $S;
  $g->write;
  $g->exists and confess "File still exists";
  success "Delete file on empty write succeeded"
 }

if (0) {                                                                        #TreadFileUsingSavedToken
  my $s = q(Hello to the World);
          &writeFileUsingSavedToken(qw(philiprbrenan ddd hello.txt), $s);
  my $S = &readFileUsingSavedToken (qw(philiprbrenan ddd hello.txt));

  confess "Read file using saved token FAILED" unless $s eq $S;
  success "Read file using saved token succeeded"
 }

if (0) {                                                                        #TsavePersonalAccessToken #TloadPersonalAccessToken
  my $d = temporaryFolder;
  my $t = join '', 1..20;

  my $g = gitHub
   (userid                    => q(philiprbrenan),
    personalAccessToken       => $t,
    personalAccessTokenFolder => $d,
   );

          $g->savePersonalAccessToken;
  my $T = $g->loadPersonalAccessToken;

  confess "Load/Save token FAILED" unless $t eq $T;
  success "Load/Save token succeeded"
 }
