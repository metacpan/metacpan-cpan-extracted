#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Create, Read, Update, Delete files, issues, web hooks and commits on GitHub.
# Per: https://developer.github.com/v3/
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------
#podDocumentation
package GitHub::Crud;
use v5.16;
our $VERSION = 20200218;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all !fileList);
use Digest::SHA1 qw(sha1_hex);
use Time::HiRes qw(time);

sub url          { "https://api.github.com/repos" }                             # Github api url
sub accessFolder { q(/etc/GitHubCrudPersonalAccessToken) };                     # Personal access tokens are stored in a file in this folder with the name of the userid of the L<GitHub> repository

my %shas;                                                                       # L<SHA> digests already seen - used to optimize write and delete

sub GitHub::Crud::Response::new($$)                                             #P Execute a request against L<GitHub> and decode the response
 {my ($gitHub, $request) = @_;                                                  # Github, request string

  my $R = bless {command=>$request}, "GitHub::Crud::Response";                  # Construct the response

  my $r = xxx $request, qr(HTTP);

  $r =~ s/\r//gs;                                                               # Internet line ends
  my ($http, @r) = split /\n/, $r;
  while(@r > 2 and $http =~ "HTTP/1.1" and $http =~ /100/)                      # Continue messages
   {shift @r; $http = shift @r;
   }

  if ($http and $http =~ "HTTP/1.1" and $http =~ /200|201|404|409|422/)
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
     {say STDERR "Add the following fields to package GitHub::Crud::Response";
      say STDERR "qw($_)," for(sort keys %can);
     }

    if (@data)                                                                  # Save any data
     {my $j = join ' ', @data;
      my $p = $R->data = bless decodeJson($j), "GitHub::Crud::Response::Data";
      if (ref($p) =~ m/hash/is and my $c = $p->content)
       {$R->content = decodeBase64($c);                                         # Decode the data
       }
     }

    ($R->status) = split / /, $R->Status;                                       # Save response status

    return $gitHub->response = $R;                                              # Return successful response
   }
  else
   {confess "Unexpected response from GitHub:\n$r\n$request\n";                 # Confess to failure
   }
 }

genHash(q(GitHub::Crud::Response),                                              # Attributes describing a response from L<GitHub>.
  Accept_Ranges                           => undef,
  Access_Control_Allow_Origin             => undef,
  Access_Control_Expose_Headers           => undef,
  Cache_Control                           => undef,
  Connection                              => undef,
  Content_Length                          => undef,
  content                                 => undef,                             # The actual content of the file from L<GitHub>.
  Content_Security_Policy                 => undef,
  Content_Type                            => undef,
  data                                    => undef,                             # The data received from L<GitHub>, normally in L<json> format.
  Date                                    => undef,
  ETag                                    => undef,
  Expires                                 => undef,
  Last_Modified                           => undef,
  Location                                => undef,
  Referrer_Policy                         => undef,
  Server                                  => undef,
  Source_Age                              => undef,
  status                                  => undef,                             # Our version of Status.
  Status                                  => undef,
  Strict_Transport_Security               => undef,
  Vary                                    => undef,
  Via                                     => undef,
  X_Accepted_OAuth_Scopes                 => undef,
  X_Cache                                 => undef,
  X_Cache_Hits                            => undef,
  X_Content_Type                          => undef,
  X_Content_Type_Options                  => undef,
  X_Fastly_Request_ID                     => undef,
  X_Frame_Options                         => undef,
  X_Geo_Block_List                        => undef,
  X_GitHub_Media_Type                     => undef,
  X_GitHub_Request_Id                     => undef,
  X_OAuth_Scopes                          => undef,
  X_RateLimit_Limit                       => undef,
  X_RateLimit_Remaining                   => undef,
  X_RateLimit_Reset                       => undef,
  X_Runtime_rack                          => undef,
  X_Served_By                             => undef,
  X_Timer                                 => undef,
  X_XSS_Protection                        => undef,
 );

genHash(q(GitHub::Crud::Response::Data),                                        # Response L<JSON> from GitHubExecute a request against L<GitHub> and decode the response
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

sub getSha($)                                                                   #P Compute L<sha> for data after encoding any unicode characters as utf8
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
  my $g             = GitHub::Crud::new(@_);
     $g->userid     = q(philiprbrenan);
     $g->repository = q(aaa);

  $g
 }

#D1 Constructor                                                                 # Create a L<github> object with the specified attributes describing the interface with L<github>.

sub new(@)                                                                      # Create a new L<GitHub> object with attributes as describe at: L<GitHub::Crud Definition>.
 {my (%attributes) = @_;                                                        # Attribute values

  my $curl = qx(curl -V);                                                       # Check Curl
  if ($curl =~ /command not found/)
   {confess "Command curl not found"
   }

  my $g = genHash(__PACKAGE__,                                                  # Attributes describing the interface with L<github>.
    body                         => undef,                                      #I The body of an issue.
    branch                       => undef,                                      #I Branch name (you should create this branch first) or omit it for the default branch which is usually 'master'.
    failed                       => undef,                                      #  Defined if the last request to L<GitHub> failed else B<undef>.
    fileList                     => undef,                                      #  Reference to an array of files produced by L<list|/list>.
    gitFile                      => undef,                                      #I File name on L<GitHub> - this name can contain '/'. This is the file to be read from, written to, copied from, checked for existence or deleted.
    gitFolder                    => undef,                                      #I Folder name on L<GitHub> - this name can contain '/'.
    message                      => undef,                                      #I Optional commit message
    nonRecursive                 => undef,                                      #I Fetch only one level of files with L<list>.
    personalAccessToken          => undef,                                      #  A personal access token with scope "public_repo" as generated on page: https://github.com/settings/tokens.
    personalAccessTokenFolder    => accessFolder,                               #I The folder into which to save personal access tokens. Set to q(/etc/GitHubCrudPersonalAccessToken) by default.
    readData                     => undef,                                      #  Data produced by L<read|/read>.
    repository                   => undef,                                      #I The name of the repository to be worked on minus the userid - you should create this repository first manually.
    response                     => undef,                                      #  A reference to L<GitHub>'s response to the latest request.
    secret                       => undef,                                      #I The secret for a web hook - this is created by the creator of the web hook and remembered by L<GitHub>,
    title                        => undef,                                      #I The title of an issue.
    webHookUrl                   => undef,                                      #I The url for a web hook.
    utf8                         => undef,                                      #I Send the data as utf8 if true - do not use this for binary files containing images or audio, just for files containing text.
    userid                       => undef,                                      #I Userid on L<GitHub> of the repository to be worked on.
   );

  $g->$_ = $attributes{$_} for sort keys %attributes;

  $g
 }

#D1 Methods                                                                     # Actions on L<GitHub>.

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

  $gitHub->failed = $r->status != 200;                                          # Check response code
# lll($gitHub, q(list));

  if ($gitHub->failed)                                                          # Failed to retrieve a list of files
   {$gitHub->fileList = [];
   }
  else
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

if (0 and !caller)                                                              # Test list
 {confess join "\n", "list:", gitHub->list, '';
 }

sub read($)                                                                     # Read data from a file on L<GitHub>.\mRequired attributes: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> = the file to read.\mOptional attributes: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.\mIf the read operation is successful, L<failed|/failed> is set to false and L<readData|/readData> is set to the data read from the file.\mIf the read operation fails then L<failed|/failed> is set to true and L<readData|/readData> is set to B<undef>.\mReturns the data read or B<undef> if no file was found.
 {my ($gitHub) = @_;                                                            # GitHub

  my $user = qm  $gitHub->userid;     $user or confess "userid required";
  my $repo = qm  $gitHub->repository; $repo or confess "repository required";
  my $file = qm $gitHub->gitFile;     $file or confess "gitFile required";
  my $bran = qm $gitHub->refOrBranch(1);
  my $pat  = $gitHub->patKey(0);

  my $url  = url;
  my $s = filePath(qq(curl -si $pat $url),
                   $user, $repo, qq(contents), $file.$bran);
  my $r = GitHub::Crud::Response::new($gitHub, $s);                             # Get response from GitHub

  $gitHub->failed = $r->status != 200;                                          # Check response code
# lll($gitHub, q(read)) unless $noLog;

  if ($gitHub->failed)                                                          # No file list supplied
   {$gitHub->readData = undef;
   }
  else
   {$gitHub->readData = decodeBase64($r->data->content);
   }

  $gitHub->readData
 }

if (0 and !caller)                                                              # Test read
 {my $g = gitHub;
  $g->gitFile = my $f = q(z'2  'z"z.data);
  $g->write("aaa");
  confess $g->read eq q(aaa) ? "Read passed\n" : "read FAILED\n";
 }

sub write($$)                                                                   # Write data into a L<GitHub> file, creating the file if it is not already present.\mRequired attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, , L<gitFile|/gitFile> = the file to be written to.\mOptional attributes: L<refOrBranch|/refOrBranch>.\mIf the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.
 {my ($gitHub, $data) = @_;                                                     # GitHub object, data to be written
  defined($data) or confess "data required";

  my $pat  = $gitHub->patKey(1);
  my $user = qm $gitHub->userid;     $user or confess "userid required";
  my $repo = qm $gitHub->repository; $repo or confess "repository required";
  my $file = qm $gitHub->gitFile;    $file or confess "gitFile required";
  my $bran = qm $gitHub->refOrBranch(0) || '?';
  my $mess = qm $gitHub->message;

  my $url  = url;
  my $s    = $gitHub->getExistingSha;                                           # Get the L<sha> of the file if the file exists
  my $sha = $s ? ', "sha": "'. $s .'"' : '';                                    # L<sha> of existing file or blank string if no existing file

  if ($s and my $S = getSha($data))                                             # L<sha> of new data
   {if ($s eq $S)                                                               # Duplicate if the L<sha>s match
     {$gitHub->failed = undef;
      return 1;
     }
   }
  if ($gitHub->utf8)                                                            # Send the data as utf8 if requested
   {use Encode 'encode';
    $data  = encode('UTF-8', $data);
   }
  my $denc = encodeBase64($data) =~ s/\n//gsr;

  my $tmpFile = writeFile(undef,                                                # Write encoded content to temporary file
          qq({"message": "$mess", "content": "$denc" $sha}));
  my $d = qq(-d @).$tmpFile;
  my $u = filePath($url, $user, $repo, qw(contents), $file.$bran);
  my $c = qq(curl -si -X PUT $pat $u $d);                                       # Curl command
  my $r = GitHub::Crud::Response::new($gitHub, $c);                             # Execute command to create response
  unlink $tmpFile;                                                              # Cleanup

  my $status = $r->status;                                                      # Check response code
  my $success = $status == 200 ? 'updated' : $status == 201 ? 'created' : undef;# Updated, created
  $gitHub->failed = $success ? undef : 1;
# lll($gitHub, q(write));

  $success                                                                      # Return true on success
 }

if (0 and !caller)                                                              # The second write should be faster because its L<sha> is known from the read
 {my $g = gitHub;
  $g->gitFile = "zzz.data";

  my $d = dateTimeStamp;

  if (1)
   {my $t = time();
    $g->write($d);
    say STDERR "First write time: ", time() -  $t;
   }

  my $r = $g->read;
  say STDERR "Write bbb: $r";
  if (1)
   {my $t = time();
    $g->write($d);
    say STDERR "Second write time: ", time() -  $t;
   }
  confess $g->read eq $d ? "Write passed\n" : "write FAILED\n";
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

if (0 and !caller)                                                              # Test copy
 {my ($f1, $f2) = ("zzz.data", "zzz2.data");
  my $g = gitHub;
  $g->gitFile   = $f2; $g->delete;
  $g->gitFile   = $f1;
  my $d = dateTimeStamp;
  my $w = $g->write($d);
  my $r = $g->copy($f2);
  say STDERR "Copy created: $r";
  $g->gitFile   = $f2;
  my $D = $g->read;
  say STDERR "Read     ccc: $D";
  confess $d eq $D ? "Copy passed\n" : "copy FAILED\n";
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

  if (!$gitHub->failed)                                                         # Look for requested file in file listing
   {for(@{$gitHub->response->data})
     {return $_ if $_->path eq $gitHub->gitFile;
     }
   }
  undef
 }

if (0 and !caller)                                                              # Test exists
 {my $g = gitHub;
  $g->gitFile    = "test4.html";
  my $d = dateTimeStamp;
  $g->write($d);
  confess "exists FAILED" unless $g->read eq $d;
  $g->delete;
  confess !$g->exists ? "Exists passed\n" : "exists FAILED\n";
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

if (0 and !caller)                                                              # Test rename
 {my ($f1, $f2) = qw(zzz.data zzz2.data);
  my $g = gitHub;
     $g->gitFile = $f2; $g->delete;

  my $d = dateTimeStamp;
  $g->gitFile  = $f1;
  $g->write($d);
  confess "rename FAILED" unless $g->read eq $d;

  $g->rename($f2);
  confess "rename FAILED" if $g->exists;

  $g->gitFile  = $f2;
  confess $g->read eq $d ? "Rename passed\n" : "rename FAILED\n";
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
# lll($gitHub, q(delete));
  $success ? 1 : undef                                                          # Return true on success
 }

if (0 and !caller)                                                              # The second delete should be faster because the fact that the file has been deleted is held in the L<sha> cache
 {my $g = gitHub;
  my $d = dateTimeStamp;
  $g->gitFile = "zzz.data";
  $g->write($d);
  confess "delete FAILED" unless $g->read eq $d;

  if (1)
   {my $t = time();
    my $d = $g->delete;
    say STDERR "Delete   1: ", $d;
    say STDERR "First delete: ", time() -  $t;
    confess "delete FAILED" if $g->exists;
   }

  if (1)
   {my $t = time();
    my $d = $g->delete;
    say STDERR "Delete   1: ", $d;
    say STDERR "Second delete: ", time() -  $t;
    confess "delete FAILED" if $g->exists;
   }
  confess !$g->exists ? "Delete passed\n" : "delete FAILED\n";
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

  $r
 }

if (0 and !caller)                                                              # Test list all branches
 {confess dump(gitHub->listCommits);
 }

sub writeCommit($$@)                                                            # Write all the named files into a L<GitHub> repository as a commit on the specified branch using a minimal number of network interactions.\mRequired attributes: L<userid|/userid>, L<repository|/repository>.\mOptional attributes: L<refOrBranch|/refOrBranch>.
 {my ($gitHub, $folder, @files) = @_;                                           # GitHub object, file prefix to remove, files to write

  my $pat    = $gitHub->patKey(1);
  my $user   = qm $gitHub->userid;     $user or confess "userid required";
  my $repo   = qm $gitHub->repository; $repo or confess "repository required";
  my $bran   = $gitHub->branch;        $bran or confess "branch required";
  my $url    = url;

  my $tree = sub                                                                # Create the tree
   {my @t;
    for my $f(@files)                                                           # Load files into a tree
     {my $p = swapFilePrefix($f, $folder);
      my $c = readFile($f);
      push @t, <<END;
 {"path"   : "$p",
  "mode"   : "100644",
  "type"   : "blob",
  "content": "$c"
 }
END
     }

    my $t = join ",\n", @t;                                                     # Assemble tree
    my $f = writeFile(undef, qq({"tree" : [$t]}));                              # Write Json
    my $c = qq(curl -si -X POST $pat -d \@$f $url/$user/$repo/git/trees);

    my $r = GitHub::Crud::Response::new($gitHub, $c);
    my $success = $r->status == 201;                                            # Check response code
    unlink $f;                                                                  # Cleanup

    $success or confess dump($r)."\nUnable to create tree\n";

    $r
   }->();

  my $commit = sub                                                              # Create a commit to hold the tree
   {my $s = $tree->data->sha;
    my $f = writeFile(undef, <<END);
{
 "message": "Committed by GitHub::Crud",
 "tree"   : "$s"
}
END

    my $c = qq(curl -si -X POST $pat -d \@$f $url/$user/$repo/git/commits);

    my $r = GitHub::Crud::Response::new($gitHub, $c);
    my $success = $r->status == 201;                                            # Check response code
    unlink $f;                                                                  # Cleanup

    $success or confess dump($r)."\nUnable to create commit\n";

    $r
   }->();

  my $branch = sub                                                              # Update branch
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

      $success or confess dump($r)."\nUnable to update branch\n";

      $r
     }->();
    return $branchUpdate;
   }

  confess "Unable to create/update branch: $bran";
 }

if (0 and !caller)                                                              # Test writing a commit
 {my $d = temporaryFolder;
  my $D = dateTimeStamp;
  for my $i(1..9)                                                               # Create some files to write
   {writeFile(fpe($d, $i, qw(data)), "$i on $D\n");
   }
  my $g = gitHub(branch=>q(test));
  my $r = writeCommit($g, $d, searchDirectoryTreesForMatchingFiles($d));
  confess "Create/Update branch succeeded exit";
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
  lll($gitHub, q(listWebHooks));
  $success ? $gitHub->response->data : undef                                    # Return reference to array of web hooks on success. If there are no web hooks set then the referenced array will be empty.
 }

if (0 and !caller)
 {my $g = gitHub;
  if (my $h = $g->listWebHooks)
   {say STDERR "Webhooks ", dump($h);
   }
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
  lll($gitHub, q(createPushWebHooks));
  $success ? 1 : undef                                                          # Return true on success
 }

if (0 and !caller)
 {my $g = gitHub;
  my $d = $g->createPushWebHook;
  say STDERR "Create web hook:\n", dump($d);
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
  lll($gitHub, q(createIssue));
  $success ? 1 : undef                                                          # Return true on success
 }

sub createIssueFromSavedToken($$$$;$)                                           # Create an issue on L<GitHub> using an access token saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.\mReturns true if the issue was created successfully else false.
 {my ($userid, $repository, $title, $body, $accessFolder) = @_;                 # Userid on GitHub, repository name, issue title, issue body, optionally the name of the folder where personal access tokens are stored if it is not the standard one specified in attribute accessFolder.
  my $g = GitHub::Crud::new;
  $g->userid     = $userid;     $userid     or confess "Userid required";
  $g->repository = $repository; $repository or confess "Repository required";
  $g->title      = $title;      $title      or confess "Title required";
  $g->body       = $body;       $body       or confess "Body required";
  $g->personalAccessTokenFolder = $accessFolder // accessFolder;
  $g->loadPersonalAccessToken;
  $g->createIssue;
 }

sub writeFileUsingSavedToken($$$$;$)                                            # Write to a file on L<GitHub> using a personal access token saved in a file.
 {my ($userid, $repository, $file, $content, $accessFolder) = @_;               # Userid on GitHub, repository name, file name on github, file content, optional: the name of the folder where personal access tokens are stored if it is not the standard one specified in attribute accessFolder.
  my $g = GitHub::Crud::new;
  $g->userid     = $userid;     $userid     or confess "Userid required";
  $g->repository = $repository; $repository or confess "Repository required";
  $g->gitFile    = $file;       $file       or confess "File required";
  $g->personalAccessTokenFolder = $accessFolder // accessFolder;
  $g->loadPersonalAccessToken;
  $g->write($content);
 }

sub writeFileFromFileUsingSavedToken($$$$;$)                                    # Copy a file to L<github>  using a personal access token saved in a file.
 {my ($userid, $repository, $file, $localFile, $accessFolder) = @_;             # Userid on GitHub, repository name, file name on github, file content, optional: the name of the folder where personal access tokens are stored if it is not the standard one specified in attribute accessFolder.
  my $g = GitHub::Crud::new;
  $g->userid     = $userid;     $userid     or confess "Userid required";
  $g->repository = $repository; $repository or confess "Repository required";
  $g->gitFile    = $file;       $file       or confess "File required";
  $g->personalAccessTokenFolder = $accessFolder // accessFolder;
  $g->loadPersonalAccessToken;
  $g->write(readBinaryFile($localFile));
 }

if (0 and !caller)
 {my $g = gitHub;
  $g->title      = "Hello";
  $g->body       = "Hello World";
  my $d = $g->createIssue;
  say STDERR "Create issue: ", dump($d);
  exit;
 }

if (0 and !caller)
 {&createIssueFromSavedToken(qw(philiprbrenan notifications Testing Hello-World));
  exit;
 }

if (0 and !caller)
 {&writeFileUsingSavedToken(qw(philiprbrenan notifications testReadME.md  Hello-World));
  exit;
 }

sub savePersonalAccessToken($)                                                  # Save a L<GitHub> personal access token by userid in folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $user = qm $gitHub->userid;           $user or confess "userid required";
  my $pat  = $gitHub->personalAccessToken; $pat  or confess "personal access token required";
  my $dir  = $gitHub->personalAccessTokenFolder // accessFolder;
  my $file = filePathExt($dir, $user, q(data));
  makePath($file);
  storeFile($file, {pat=>$pat});                                                # Store personal access token
  -e $file or confess "Unable to store personal access token in file:\n$file";  # Complain if store fails
  my $p = retrieve $file;
  $pat eq $p->{pat} or                                                          # Check file format
    confess "File contains the wrong personal access token:\n$file";
 }

sub loadPersonalAccessToken($)                                                  # Load a personal access token by userid from folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $user = qm $gitHub->userid;           $user or confess "userid required";
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
@EXPORT_OK    = qw(writeFileUsingSavedToken writeFileFromFileUsingSavedToken);
%EXPORT_TAGS  = (all=>[@EXPORT_OK]);

#-------------------------------------------------------------------------------
# Tests
#-------------------------------------------------------------------------------

if (0 and !caller)
 {my $g = gitHub;
  $g->gitFile = "testFromAppaApps.html";

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

Create, Read, Update, Delete files, issues, web hooks and commits on GitHub.

=head1 Synopsis

Create, Read, Update, Delete files, issues, web hooks and commits on GitHub as
described at:

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

  say STDERR
     "Write : ", dump($g->write(join '-', 1..9)),
   "\nRead 1: ", dump($g->read),
   "\nDelete: ", dump($g->delete),
   "\nRead 2: ", dump($g->read);

Produces:

 Write : 'created';
 Read 1: "1-2-3-4-5-6-7-8-9"
 Delete: 1
 Read 2: undef

=head1 Description



Version 20200218.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Constructor

Create a L<GitHub|https://github.com> object with the specified attributes describing the interface with L<GitHub|https://github.com>.

=head2 new(%attributes)

Create a new L<GitHub|https://github.com> object with attributes as describe at: L<GitHub::Crud Definition>.

     Parameter    Description
  1  %attributes  Attribute values

=head1 Methods

Actions on L<GitHub|https://github.com>.

=head2 list($gitHub)

List all the files contained in a L<GitHub|https://github.com> repository or all the files below a specified folder in the repository.

Required attributes: L<userid|/userid>, L<repository|/repository>.

Optional attributes: L<gitFolder|/gitFolder>, L<refOrBranch|/refOrBranch>, L<nonRecursive|/nonRecursive>, L<patKey|/patKey>.

Use the L<gitFolder|/gitFolder> parameter to specify the folder to start the list from, by default, the listing will start at the root folder of your repository.

Use the L<nonRecursive|/nonRecursive> option if you require only the files in the start folder as otherwise all the folders in the start folder will be listed as well which might take some time.

If the list operation is successful, L<failed|/failed> is set to false and L<fileList|/fileList> is set to refer to an array of the file names found.

If the list operation fails then L<failed|/failed> is set to true and L<fileList|/fileList> is set to refer to an empty array.

Returns the list of file names found or empty list if no files were found.

     Parameter  Description
  1  $gitHub    GitHub

=head2 read($gitHub)

Read data from a file on L<GitHub|https://github.com>.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> = the file to read.

Optional attributes: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.

If the read operation is successful, L<failed|/failed> is set to false and L<readData|/readData> is set to the data read from the file.

If the read operation fails then L<failed|/failed> is set to true and L<readData|/readData> is set to B<undef>.

Returns the data read or B<undef> if no file was found.

     Parameter  Description
  1  $gitHub    GitHub

=head2 write($gitHub, $data)

Write data into a L<GitHub|https://github.com> file, creating the file if it is not already present.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, , L<gitFile|/gitFile> = the file to be written to.

Optional attributes: L<refOrBranch|/refOrBranch>.

If the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.

     Parameter  Description
  1  $gitHub    GitHub object
  2  $data      Data to be written

=head2 copy($gitHub, $target)

Copy a source file from one location to another target location in your L<GitHub|https://github.com> repository, overwriting the target file if it already exists.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be copied.

Optional attributes: L<refOrBranch|/refOrBranch>.

If the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.

     Parameter  Description
  1  $gitHub    GitHub object
  2  $target    The name of the file to be created

=head2 exists($gitHub)

Test whether a file exists on L<GitHub|https://github.com> or not and returns an object including the B<sha> and B<size> fields if it does else L<undef|https://perldoc.perl.org/functions/undef.html>.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> file to test.

Optional attributes: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.

     Parameter  Description
  1  $gitHub    GitHub object

=head2 rename($gitHub, $target)

Rename a source file on L<GitHub|https://github.com> if the target file name is not already in use.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be renamed.

Optional attributes: L<refOrBranch|/refOrBranch>.

Returns the new name of the file B<renamed> if the rename was successful else B<undef> if the rename failed.

     Parameter  Description
  1  $gitHub    GitHub object
  2  $target    The new name of the file

=head2 delete($gitHub)

Delete a file from L<GitHub|https://github.com>.

Required attributes: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be deleted.

Optional attributes: L<refOrBranch|/refOrBranch>.

If the delete operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the delete was successful else false.

     Parameter  Description
  1  $gitHub    GitHub object

=head2 listCommits($gitHub)

List all the commits in a L<GitHub|https://github.com> repository.

Required attributes: L<userid|/userid>, L<repository|/repository>.

     Parameter  Description
  1  $gitHub    GitHub object

=head2 writeCommit($gitHub, $folder, @files)

Write all the named files into a L<GitHub|https://github.com> repository as a commit on the specified branch using a minimal number of network interactions.

Required attributes: L<userid|/userid>, L<repository|/repository>.

Optional attributes: L<refOrBranch|/refOrBranch>.

     Parameter  Description
  1  $gitHub    GitHub object
  2  $folder    File prefix to remove
  3  @files     Files to write

=head2 listWebHooks($gitHub)

List web hooks associated with your L<GitHub|https://github.com> repository.

Required: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>.

If the list operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the list  operation was successful else false.

     Parameter  Description
  1  $gitHub    GitHub object

=head2 createPushWebHook($gitHub)

Create a web hook for your L<GitHub|https://github.com> userid.

Required: L<userid|/userid>, L<repository|/repository>, L<url|/url>, L<patKey|/patKey>.

Optional: L<secret|/secret>.

If the create operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the web hook was created successfully else false.

     Parameter  Description
  1  $gitHub    GitHub object

=head2 createIssue($gitHub)

Create an issue on L<GitHub|https://github.com>.

Required: L<userid|/userid>, L<repository|/repository>, L<body|/body>, L<title|/title>.

If the operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the issue was created successfully else false.

     Parameter  Description
  1  $gitHub    GitHub object

=head2 createIssueFromSavedToken($userid, $repository, $title, $body, $accessFolder)

Create an issue on L<GitHub|https://github.com> using an access token saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.

Returns true if the issue was created successfully else false.

     Parameter      Description
  1  $userid        Userid on GitHub
  2  $repository    Repository name
  3  $title         Issue title
  4  $body          Issue body
  5  $accessFolder  Optionally the name of the folder where personal access tokens are stored if it is not the standard one specified in attribute accessFolder.

=head2 writeFileUsingSavedToken($userid, $repository, $file, $content, $accessFolder)

Write to a file on L<GitHub|https://github.com> using an access token saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.

Returns true if the data was stored successfully else false.

     Parameter      Description
  1  $userid        Userid on GitHub
  2  $repository    Repository name
  3  $file          File name on github
  4  $content       File content
  5  $accessFolder  Optional: the name of the folder where personal access tokens are stored if it is not the standard one specified in attribute accessFolder.

=head2 writeFileFromFileUsingSavedToken($userid, $repository, $file, $localFile, $accessFolder)

Write to a L<GitHub|https://github.com> repository owned by B<$userid> with repository name B<$repository> writing into file B<$file> the contents of the local file B<$localFile> using L<savePersonalAccessToken|/savePersonalAccessToken>.

Returns true if the data was stored successfully else false.

     Parameter      Description
  1  $userid        Userid on GitHub
  2  $repository    Repository name
  3  $file          File name on github
  4  $localFile     File content
  5  $accessFolder  Optional: the name of the folder where personal access tokens are stored if it is not the standard one specified in attribute accessFolder.

=head2 savePersonalAccessToken($gitHub)

Save a L<GitHub|https://github.com> personal access token by userid in folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.

     Parameter  Description
  1  $gitHub    GitHub object

=head2 loadPersonalAccessToken($gitHub)

Load a personal access token by userid from folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.

     Parameter  Description
  1  $gitHub    GitHub object


=head2 GitHub::Crud Definition


Attributes describing the interface with L<GitHub|https://github.com>.




=head3 Input fields


B<body> - The body of an issue.

B<branch> - Branch name (you should create this branch first) or omit it for the default branch which is usually 'master'.

B<gitFile> - File name on L<GitHub|https://github.com> - this name can contain '/'. This is the file to be read from, written to, copied from, checked for existence or deleted.

B<gitFolder> - Folder name on L<GitHub|https://github.com> - this name can contain '/'.

B<message> - Optional commit message

B<nonRecursive> - Fetch only one level of files with L<list>.

B<personalAccessTokenFolder> - The folder into which to save personal access tokens. Set to q(/etc/GitHubCrudPersonalAccessToken) by default.

B<repository> - The name of the repository to be worked on minus the userid - you should create this repository first manually.

B<secret> - The secret for a web hook - this is created by the creator of the web hook and remembered by L<GitHub|https://github.com>,

B<title> - The title of an issue.

B<userid> - Userid on L<GitHub|https://github.com> of the repository to be worked on.

B<utf8> - Send the data as utf8 if true - do not use this for binary files containing images or audio, just for files containing text.

B<webHookUrl> - The url for a web hook.



=head3 Output fields


B<failed> - Defined if the last request to L<GitHub|https://github.com> failed else B<undef>.

B<fileList> - Reference to an array of files produced by L<list|/list>.

B<personalAccessToken> - A personal access token with scope "public_repo" as generated on page: https://github.com/settings/tokens.

B<readData> - Data produced by L<read|/read>.

B<response> - A reference to L<GitHub|https://github.com>'s response to the latest request.



=head2 GitHub::Crud::Response Definition


Attributes describing a response from L<GitHub|https://github.com>.




=head3 Output fields


B<content> - The actual content of the file from L<GitHub|https://github.com>.

B<data> - The data received from L<GitHub|https://github.com>, normally in L<Json|https://en.wikipedia.org/wiki/JSON> format.

B<status> - Our version of Status.



=head1 Index


1 L<copy|/copy> - Copy a source file from one location to another target location in your L<GitHub|https://github.com> repository, overwriting the target file if it already exists.

2 L<createIssue|/createIssue> - Create an issue on L<GitHub|https://github.com>.

3 L<createIssueFromSavedToken|/createIssueFromSavedToken> - Create an issue on L<GitHub|https://github.com> using an access token saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.

4 L<createPushWebHook|/createPushWebHook> - Create a web hook for your L<GitHub|https://github.com> userid.

5 L<delete|/delete> - Delete a file from L<GitHub|https://github.com>.

6 L<exists|/exists> - Test whether a file exists on L<GitHub|https://github.com> or not and returns an object including the B<sha> and B<size> fields if it does else L<undef|https://perldoc.perl.org/functions/undef.html>.

7 L<list|/list> - List all the files contained in a L<GitHub|https://github.com> repository or all the files below a specified folder in the repository.

8 L<listCommits|/listCommits> - List all the commits in a L<GitHub|https://github.com> repository.

9 L<listWebHooks|/listWebHooks> - List web hooks associated with your L<GitHub|https://github.com> repository.

10 L<loadPersonalAccessToken|/loadPersonalAccessToken> - Load a personal access token by userid from folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.

11 L<new|/new> - Create a new L<GitHub|https://github.com> object with attributes as describe at: L<GitHub::Crud Definition>.

12 L<read|/read> - Read data from a file on L<GitHub|https://github.com>.

13 L<rename|/rename> - Rename a source file on L<GitHub|https://github.com> if the target file name is not already in use.

14 L<savePersonalAccessToken|/savePersonalAccessToken> - Save a L<GitHub|https://github.com> personal access token by userid in folder L<personalAccessTokenFolder|/personalAccessTokenFolder>.

15 L<write|/write> - Write data into a L<GitHub|https://github.com> file, creating the file if it is not already present.

16 L<writeCommit|/writeCommit> - Write all the named files into a L<GitHub|https://github.com> repository as a commit on the specified branch using a minimal number of network interactions.

17 L<writeFileFromFileUsingSavedToken|/writeFileFromFileUsingSavedToken> - Write to a L<GitHub|https://github.com> repository owned by B<$userid> with repository name B<$repository> writing into file B<$file> the contents of the local file B<$localFile> using L<savePersonalAccessToken|/savePersonalAccessToken>.

18 L<writeFileUsingSavedToken|/writeFileUsingSavedToken> - Write to a file on L<GitHub|https://github.com> using an access token saved in a file using L<savePersonalAccessToken|/savePersonalAccessToken>.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install GitHub::Crud

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

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

ok qm(qq('"\ abc)) eq q(\'\"%20abc);
