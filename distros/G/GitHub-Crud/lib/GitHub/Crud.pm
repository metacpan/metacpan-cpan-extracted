#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Create, Read, Update, Delete files on GitHub
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------
#podDocumentation

package GitHub::Crud;
use v5.16;
our $VERSION = '20180616';
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(appendFile binModeAllUtf8 dateTimeStamp decodeBase64 decodeJson encodeBase64 encodeJson filePath filePathDir filePathExt genLValueScalarMethods makePath readFile temporaryFile writeFile xxx);
use Digest::SHA1 qw(sha1_hex);
use Storable qw(store retrieve);
use Time::HiRes qw(time);
use utf8;

sub url          { "https://api.github.com/repos" }                             # Github api url
sub accessFolder { q(/etc/GitHubCrudPersonalAccessToken) };                     # Personal access tokens are stored in a file in this folder with the name of the userid of the GitHub repository

my %shas;                                                                       # SHAs seen - used to optimize write and delete

#1 Attributes                                                                   # Create a L<new()|/new> object and then set these attributes to specify your request to GitHub

genLValueScalarMethods(qw(body));                                               # The body of an issue
genLValueScalarMethods(qw(branch));                                             # Branch name (you should create this branch first) or omit it for the default branch which is usually 'master'
genLValueScalarMethods(qw(failed));                                             # Defined if the last request to Github failed else B<undef>.
genLValueScalarMethods(qw(fileList));                                           # Reference to an array of files produced by L<list|/list>
genLValueScalarMethods(qw(gitFile));                                            # File name on GitHub - this name can contain '/'. This is the file to be read from, written to, copied from, checked for existence or deleted
genLValueScalarMethods(qw(gitFolder));                                          # Folder name on GitHub - this name can contain '/'
genLValueScalarMethods(qw(logFile));                                            # The name of a local file  to which to write error messages if any errors occur.
genLValueScalarMethods(qw(message));                                            # Optional commit message
genLValueScalarMethods(qw(nonRecursive));                                       # Do a non recursive L<list|/list> - the default is to list all the sub folders found in a folder  but this takes too much time if you are only interested in the files in the start folder
genLValueScalarMethods(qw(personalAccessToken));                                # A personal access token with scope "public_repo" as generated on page: https://github.com/settings/tokens
genLValueScalarMethods(qw(personalAccessTokenFolder));                          # The folder into which to save personal access tokens. Set to q(/etc/GitHubCrudPersonalAccessToken) by default.
genLValueScalarMethods(qw(readData));                                           # Data produced by L<read|/read>
genLValueScalarMethods(qw(repository));                                         # The name of your repository minus the userid - you should create this repository first manually.
genLValueScalarMethods(qw(response));                                           # A reference to GitHub's response to the latest request
genLValueScalarMethods(qw(secret));                                             # The secret for a web hook - this is created by the creator of the web hook and remembered by GitHuib
genLValueScalarMethods(qw(title));                                              # The title of an issue
genLValueScalarMethods(qw(webHookUrl));                                         # The url for a web hook
genLValueScalarMethods(qw(utf8));                                               # Send the data as utf8 - do not use this for binary files containing images or audio, just for files containing text
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
          else {$can{$name}++}                                                  # Write list of new methods required
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

    return $gitHub->response = $R;                                              # Return successful response
   }
  else
   {confess "Unexpected response from GitHub:\n$r\n$request\n";                   # Confess to failure
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
qw(Location),
qw(Referrer_Policy),
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
# Compute sha for data after encoding any unicode characters as utf8
#-------------------------------------------------------------------------------

sub getSha($)
 {my ($data) = @_;
  my $length = length($data);
  my $blob   = 'blob' . " $length\0" . $data;
  utf8::encode($blob);
  my $r = eval{sha1_hex($blob)};
  confess $@ if $@;
  $r
 }

if (0)
 {my $sha = getSha("<h1>Hello World</h1>\n");
  my $Sha = "f3e333e80d224c631f2ff51b9b9f7189ad349c15";
  unless($sha eq $Sha)
   {confess "Wrong SHA: $sha".
            "Should be: $Sha";
   }
 }

sub shaKey($;$)                                                                 # Key to use to save/get the SHA
 {my ($gitHub, $fileData) = @_;                                                 # Github, optional fileData to specify the file incolved if not gitFile
  filePath($gitHub->repository,
   $fileData ? ($fileData->path, $fileData->name) : $gitHub->gitFile)
 }

sub saveSha($$)                                                                 # Save the sha of a file
 {my ($gitHub, $fileData) = @_;                                                 # Github, file details returned by list or exists
  $shas{$gitHub->shaKey($fileData)} = $fileData->sha;
 }

sub copySha($)                                                                  # Save the sha of a file  just read to a file just about to be written
 {my ($gitHub) = @_;                                                            # Github
  $shas{$gitHub->shaKey}  = $gitHub->response->data->sha;
 }

sub getExistingSha($)                                                           # Get the sha of a file that already exists
 {my ($gitHub) = @_;                                                            # Github
  my $s = $shas{$gitHub->shaKey};                                               # Get the sha from the saved SHAs if possible
  return $s if defined $s;                                                      # A special SHA of 0 means the file was deleted
  my $r = $gitHub->exists;                                                      # Get the sha of the file via exists if the file exists
  return $r->sha if $r;                                                         # Sha of existing file
  undef                                                                         # Undef if no such file
 }

sub deleteSha($)                                                                # Delete a SHA that is no longer valid
 {my ($gitHub) = @_;                                                            # Github
  $shas{$gitHub->shaKey} = undef                                                # Mark the SHA as deleted
 }

sub qm($)                                                                       # Quotemeta extended to include undef
 {my ($s) = @_;                                                                 # String to quote
  return '' unless $s;
  $s =~ s((\'|\"|\\)) (\\$1)gs;
  $s =~ s(\s) (%20)gsr;                                                         # Url encode blanks
 }

#-------------------------------------------------------------------------------
# Personal access token string
#-------------------------------------------------------------------------------

sub patRequired                                                                 ## Complain about the access token
 {confess "Personal access token required with scope \"public_repo\"".
          " as generated on page:\nhttps://github.com/settings/tokens";
 }

sub patKey($$)
 {my ($gitHub, $required) = @_;                                                 ## GitHub, whether the personal access key is required
  my $pat      = $gitHub->personalAccessToken;
  if (!$pat)
   {return '' unless $required;
    patRequired;
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

#-------------------------------------------------------------------------------
# Log an error message
#-------------------------------------------------------------------------------

sub lll($$)
 {my ($gitHub, $op) = @_;
  return unless $gitHub->failed;                                                # No error so no need to write a message
  return unless my $log = $gitHub->logFile;                                     # Cannot log unless the caller supplied a log file
  appendFile($log, "GitHub::Crud::$op failed:\n".dump($gitHub));
 }

#-------------------------------------------------------------------------------
# Create a test GitHub object
#-------------------------------------------------------------------------------

sub gitHub
 {my $g = GitHub::Crud::new();
  my $credentials = 'personalAccessToken.data';                                 # This file is not shipped with the distribution as it contains user specific data

  my ($pat, $testUserid, $testRepository, $testUrl, $testSecret) = sub          # A sample access token that is not included in the distribution
   {return (undef) x 5 unless -e $credentials;
    split /\n/, readFile($credentials);
   }->();

  $g->userid     = $testUserid;
  $g->repository = $testRepository;
  $g->personalAccessToken = $pat;
  $g->webHookUrl = $testUrl;
  $g->secret     = $testSecret;
  $g
 }

#1 Methods available

sub new                                                                         # Create a new GitHub object.
 {my $curl = qx(curl -V);                                                       # Check Curl
  if ($curl =~ /command not found/)
   {confess "Command curl not found"
   }
  return bless {personalAccessTokenFolder=>accessFolder}
 }

sub list($)                                                                     # List all the files contained in a GitHub repository or all the files below a specified folder in the repository.\mRequired parameters: L<userid|/userid>, L<repository|/repository>.\mOptional parameters: L<gitFolder|/gitFolder>, L<refOrBranch|/refOrBranch>, L<nonRecursive|/nonRecursive>, L<patKey|/patKey>.\mUse the L<gitFolder|/gitFolder> parameter to specify the folder to start the list from, by default, the listing will start at the root folder of your repository.\mUse the L<nonRecursive|/nonRecursive> option if you require only the files in the start folder as otherwise all the folders in the start folder will be listed as well which might take some time.\mIf the list operation is successful, L<failed|/failed> is set to false and L<fileList|/fileList> is set to refer to an array of the file names found.\mIf the list operation fails then L<failed|/failed> is set to true and L<fileList|/fileList> is set to refer to an empty array.\mReturns the list of file names found or empty list if no files were found.
 {my ($gitHub) = @_;                                                            # GitHub object
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

  my ($status) = split / /, $r->Status;                                         # Check response code
  $gitHub->failed = $status != 200;
  lll($gitHub, q(list));

  if ($gitHub->failed)                                                          # No file list supplied
   {$gitHub->fileList = [];
   }
  else
   {for(@{$r->data})                                                            # Objectify and save SHAs
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

if (0 and !caller)
 {say STDERR "list:\n", join "\n", gitHub->list;
 }

sub read($;$)                                                                   # Read data from a file on GitHub.\mRequired parameters: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> = the file to read.\mOptional parameters: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.\mIf the read operation is successful, L<failed|/failed> is set to false and L<readData|/readData> is set to the data read from the file.\mIf the read operation fails then L<failed|/failed> is set to true and L<readData|/readData> is set to B<undef>.\mReturns the data read or B<undef> if no file was found.
 {my ($gitHub, $noLog) = @_;                                                    # GitHub object, whether to log errors or not
  my $user = qm  $gitHub->userid;     $user or confess "userid required";
  my $repo = qm  $gitHub->repository; $repo or confess "repository required";
  my $file = qm $gitHub->gitFile;     $file or confess "gitFile required";
  my $bran = qm $gitHub->refOrBranch(1);
  my $pat  = $gitHub->patKey(0);
  my $url  = url;
  my $s = filePath(qq(curl -si $pat $url),
                   $user, $repo, qq(contents), $file.$bran);
  my $r = GitHub::Crud::Response::new($gitHub, $s);                             # Get response from GitHub

  my ($status) = split / /, $r->Status;                                         # Check response code
  $gitHub->failed = $status != 200;
  lll($gitHub, q(read)) unless $noLog;

  if ($gitHub->failed)                                                          # No file list supplied
   {$gitHub->readData = undef;
   }
  else
   {$gitHub->readData = decodeBase64($r->data->content);
   }

  $gitHub->readData
 }

if (0 and !caller)
 {my $g = gitHub;
  $g->gitFile = q(z'2  'z"z.data);
  $g->write("aaa");
  say STDERR "Read aaa: ", dump($g->read);
  exit;
 }

sub write($$)                                                                   # Write data into a GitHub file, creating the file if it is not already present.\mRequired parameters: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, , L<gitFile|/gitFile> = the file to be written to.\mOptional parameters: L<refOrBranch|/refOrBranch>.\mIf the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.
 {my ($gitHub, $data) = @_;                                                     # GitHub object, data to be written
  defined($data) or confess "data required";
  my $pat  = $gitHub->patKey(1);
  my $user = qm $gitHub->userid;     $user or confess "userid required";
  my $repo = qm $gitHub->repository; $repo or confess "repository required";
  my $file = qm $gitHub->gitFile;    $file or confess "gitFile required";
  my $bran = qm $gitHub->refOrBranch(0) || '?';
  my $mess = qm $gitHub->message;
  my $url  = url;
  my $s    = $gitHub->getExistingSha;                                           # Get the SHA of the file if the file exists
  my $sha = $s ? ', "sha": "'. $s .'"' : '';                                    # Sha of existing file or blank string if no existing file

  if ($s and my $S = getSha($data))                                             # Sha of new data
   {if ($s eq $S)                                                               # Duplicate if the shas match
     {$gitHub->failed = undef;
      return 1;
     }
   }
  if ($gitHub->utf8)                                                            # Send the data as utf8 if requested
   {use Encode 'encode';
    $data  = encode('UTF-8', $data);
   }
  my $denc = encodeBase64($data) =~ s/\n//gsr;

  writeFile(my $tmpFile = temporaryFile(),                                      # Write encoded content to temporary file
            qq({"message": "$mess", "content": "$denc" $sha}));
  my $d = qq(-d @).$tmpFile;
  my $u = filePath($url, $user, $repo, qw(contents), $file.$bran);
  my $c = qq(curl -si -X PUT $pat $u $d);                                       # Curl command
  my $r = GitHub::Crud::Response::new($gitHub, $c);                             # Execute command to create response
  unlink $tmpFile;                                                              # Cleanup

  my ($status) = split / /, $r->Status;                                         # Check response code

  my $success = $status == 200 ? 'updated' : $status == 201 ? 'created' : undef;# Updated, created
  $gitHub->failed = $success ? undef : 1;
  lll($gitHub, q(write));

  $success                                                                      # Return true on success
 }

if (0 and !caller)                                                              # The second write should be faster because its SHA is known from the read
 {my $g = gitHub;
  $g->gitFile = "zzz.data";
  my $d = "bbb";
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
 }

sub copy($$)                                                                    # Copy a source file from one location to another target location in your GitHub repository, overwriting the target file if it already exists.\mRequired parameters: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be copied.\mOptional parameters: L<refOrBranch|/refOrBranch>.\mIf the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.
 {my ($gitHub, $target) = @_;                                                   # GitHub object, the name of the file to be created
  defined($target) or confess "Specify the name of the file to be copied to";
  my $r = $gitHub->read;                                                        # Read the content of the source file
  if (defined $r)
   {my $file = $gitHub->gitFile;                                                # Save current source file
    my $sha  = $gitHub->response->data->sha;                                    # SHA of last file read
    $gitHub->gitFile = $target;                                                 # Set target file as current file
    my $R = $gitHub->write($r);                                                 # Write content to target file
    $gitHub->copySha;                                                           # Copy the SHA from the file just read
    $gitHub->gitFile = $file;                                                   # Restore source file
    return $R;                                                                  # Return response from write
   }
  undef                                                                         # Failed
 }

if (0 and !caller)
 {my ($f1, $f2) = ("zzz.data", "zzz2.data");
  my $g = gitHub;
  $g->gitFile   = $f2; $g->delete;
  $g->gitFile   = $f1;
  my $w = $g->write("ccc");
  my $r = $g->copy($f2);
  say STDERR "Copy created: $r";
  $g->gitFile   = $f2;
  my $d = $g->read;
  say STDERR "Read     ccc: $d";
 }

sub exists($)                                                                   # Test whether a file exists on GitHub or not and returns an object including the B<sha> and B<size> fields if it does else undef.\mRequired parameters: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> file to test.\mOptional parameters: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.
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

if (0 and !caller)
 {my $g = gitHub;
  $g->gitFile    = "test4.html";
  $g->write('aaa');
  say STDERR "Exists  AAAA: ", dump($g->exists);
  $g->delete;
  say STDERR "Exists undef: ", dump($g->exists);
 }

sub rename($$)                                                                  # Rename a source file on GitHub if the target file name is not already in use.\mRequired parameters: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be renamed.\mOptional parameters: L<refOrBranch|/refOrBranch>.\mReturns the new name of the file B<renamed> if the rename was successful else B<undef> if the rename failed.
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

if (0 and !caller)
 {my ($f1, $f2) = qw(zzz.data zzz2.data);
  my $g = gitHub;

  $g->gitFile  = $f2;
  $g->delete;
  say STDERR "Exists undef: ", dump($g->exists);

  $g->gitFile  = $f1;
  $g->write('aaa');
  say STDERR "Exists     1: ", !!$g->exists;

  $g->rename($f2);
  say STDERR "Exists undef: ", dump($g->exists);
 }

sub delete($)                                                                   # Delete a file from GitHub.\mRequired parameters: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be deleted.\mOptional parameters: L<refOrBranch|/refOrBranch>.\mIf the delete operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the delete was successful else false.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat  = $gitHub->patKey(1);
  my $user = qm $gitHub->userid;     $user or confess "userid required";
  my $repo = qm $gitHub->repository; $repo or confess "repository required";
  my $file = qm $gitHub->gitFile;    $file or confess "file to delete required";
  my $bran = qm $gitHub->refOrBranch(0);
  my $url  = url;

  my $s = $gitHub->getExistingSha;                                              # Sha of existing file or undef
  return 2 unless $s;                                                           # File already deleted
  my $sha = ' -d \'{"message": "", "sha": "'. $s .'"}\'';
  my $u = filePath($url, $user, $repo, qw(contents), $file.$bran.$sha);
  my $d = "curl -si -X DELETE $pat $u";
  my $r = GitHub::Crud::Response::new($gitHub, $d);
  my ($status) = split / /, $r->Status;                                         # Check response code
  my $success = $status == 200;
  $gitHub->deleteSha  if $success;                                              # The SHA is no longer valid
  $gitHub->failed = $success ? undef : 1;
  lll($gitHub, q(delete));
  $success ? 1 : undef                                                          # Return true on success
 }

if (0 and !caller)                                                              # The second delete should be faster because the fact that the file has been deleted is held in the SHA cache
 {my $g = gitHub;
  $g->gitFile = "zzz.data";
  $g->write('aaa');
  say STDERR "Read   aaa: ", $g->read;
  if (1)
   {my $t = time();
    my $d = $g->delete;
    say STDERR "Delete   1: ", $d;
    say STDERR "First delete: ", time() -  $t;
   }
  say STDERR "Read undef: ", dump($g->read);
  if (1)
   {my $t = time();
    my $d = $g->delete;
    say STDERR "Delete   1: ", $d;
    say STDERR "Second delete: ", time() -  $t;
   }
 }

sub listWebHooks($)                                                             # List web hooks.\mRequired: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>. \mIf the list operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the list  operation was successful else false.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat  = $gitHub->patKey(1);
  my $user = qm $gitHub->userid;     $user or confess "userid required";
  my $repo = qm $gitHub->repository; $repo or confess "repository required";
  my $bran = qm $gitHub->refOrBranch(0);
  my $url  = url;

  my $u    = filePath($url, $user, $repo, qw(hooks));
  my $s    = "curl -si $pat $u";
  my $r    = GitHub::Crud::Response::new($gitHub, $s);
  my ($status) = split / /, $r->Status;                                         # Check response code
  my $success = $status =~ m(200|201);                                          # Present or not present
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

sub createPushWebHook($)                                                        # Create a web hook.\mRequired: L<userid|/userid>, L<repository|/repository>, L<url|/url>, L<patKey|/patKey>.\mOptional: L<secret|/secret>.\mIf the create operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the web hook was created successfully else false.
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
  lll($gitHub, q(createPushWebHooks));
  $success ? 1 : undef                                                          # Return true on success
 }

if (0 and !caller)
 {my $g = gitHub;
  my $d = $g->createPushWebHook;
  say STDERR "Create web hook:\n", dump($d);
 }

sub createIssue($)                                                              # Create an issue.\mRequired: L<userid|/userid>, L<repository|/repository>, L<body|/body>, L<title|/title>.\mIf the operation is successful, L<failed|/failed> is set to false otherwise it is set to true.\mReturns true if the issue was created successfully else false.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $pat    = $gitHub->patKey(1);
  my $user   = qm $gitHub->userid;     $user   or confess "userid required";
  my $repo   = qm $gitHub->repository; $repo   or confess "repository required";
  my $body   =    $gitHub->body;       $body   or confess "body required";
  my $title  =    $gitHub->title;      $title  or confess "title required";
  my $bran   = qm $gitHub->refOrBranch(0);
  my $url    = url;

  my $json   = encodeJson({body=>$body,  title=>$title});                       # Issue in json
  writeFile(my $tmpFile = temporaryFile(), $json);                              # Write issue definition
  my $d = q( -d @).$tmpFile;
  my $u = filePath($url, $user, $repo, qw(issues));
  my $s = "curl -si -X POST $pat $u $d";                                        # Create url
  my $r = GitHub::Crud::Response::new($gitHub, $s);
  my ($status) = split / /, $r->Status;                                         # Check response code
  my $success = $status == 201;
  unlink $tmpFile;                                                              # Cleanup
  $gitHub->failed = $success ? undef : 1;
  lll($gitHub, q(createIssue));
  $success ? 1 : undef                                                          # Return true on success
 }

if (0 and !caller)
 {my $g = gitHub;
  $g->title      = "Hello";
  $g->body       = "Hello World";
  my $d = $g->createIssue;
  say STDERR "Create issue: ", dump($d);
  exit;
 }

sub savePersonalAccessToken($)                                                  # Save the personal access token by userid in folder L<personalAccessTokenFolder()|/personalAccessTokenFolder>.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $user = qm $gitHub->userid;           $user or confess "userid required";
  my $pat  = $gitHub->personalAccessToken; $pat or patRequired;
  my $dir  = $gitHub->personalAccessTokenFolder // accessFolder;
  my $file = filePathExt($dir, $user, q(data));
  makePath($file);
  store {pat=>$pat}, $file;                                                     # Store personal access token
  -e $file or confess "Unable to store personal access token in file:\n$file";  # Complain if store fails
  my $p = retrieve $file;
  $pat eq $p->{pat} or                                                          # Check file format
    confess "File contains the wrong personal access token:\n$file";
 }

sub loadPersonalAccessToken($)                                                  # Load the personal access token by userid from folder L<personalAccessTokenFolder()|/personalAccessTokenFolder>.
 {my ($gitHub) = @_;                                                            # GitHub object
  my $user = qm $gitHub->userid;           $user or confess "userid required";
  my $dir  = $gitHub->personalAccessTokenFolder // accessFolder;
  my $file = filePathExt($dir, $user, q(data));
  my $p = retrieve $file;
  my $a = $p->{pat} or                                                          # Check file format
    confess "File does not contain a personal access token:\n$file";
  $gitHub->personalAccessToken = $a;                                            # Retrieve token
 }

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

GitHub::Crud - Create, Read, Update, Delete files on GitHub.

=head1 Synopsis

Create, Read, Update, Delete files on GitHub as described at:

  https://developer.github.com/v3/repos/contents/#update-a-file

and also copy files, rename files and check whether files exist.

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

Create, Read, Update, Delete files on GitHub.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Attributes

Create a L<new()|/new> object and then set these attributes to specify your request to GitHub

=head2 body :lvalue

The body of an issue


=head2 branch :lvalue

Branch name (you should create this branch first) or omit it for the default branch which is usually 'master'


=head2 failed :lvalue

Defined if the last request to Github failed else B<undef>.


=head2 fileList :lvalue

Reference to an array of files produced by L<list|/list>


=head2 gitFile :lvalue

File name on GitHub - this name can contain '/'. This is the file to be read from, written to, copied from, checked for existence or deleted


=head2 gitFolder :lvalue

Folder name on GitHub - this name can contain '/'


=head2 logFile :lvalue

The name of a local file  to which to write error messages if any errors occur.


=head2 message :lvalue

Optional commit message


=head2 nonRecursive :lvalue

Do a non recursive L<list|/list> - the default is to list all the sub folders found in a folder  but this takes too much time if you are only interested in the files in the start folder


=head2 personalAccessToken :lvalue

A personal access token with scope "public_repo" as generated on page: https://github.com/settings/tokens


=head2 personalAccessTokenFolder :lvalue

The folder into which to save personal access tokens. Set to q(/etc/GitHubCrudPersonalAccessToken) by default.


=head2 readData :lvalue

Data produced by L<read|/read>


=head2 repository :lvalue

The name of your repository minus the userid - you should create this repository first manually.


=head2 response :lvalue

A reference to GitHub's response to the latest request


=head2 secret :lvalue

The secret for a web hook - this is created by the creator of the web hook and remembered by GitHuib


=head2 title :lvalue

The title of an issue


=head2 webHookUrl :lvalue

The url for a web hook


=head2 utf8 :lvalue

Send the data as utf8 - do not use this for binary files containing images or audio, just for files containing text


=head2 userid :lvalue

Your userid on GitHub


=head2 writeData :lvalue

Data to be written by L<write|/write>


=head1 Methods available

=head2 new()

Create a new GitHub object.


=head2 list($)

List all the files contained in a GitHub repository or all the files below a specified folder in the repository.

Required parameters: L<userid|/userid>, L<repository|/repository>.

Optional parameters: L<gitFolder|/gitFolder>, L<refOrBranch|/refOrBranch>, L<nonRecursive|/nonRecursive>, L<patKey|/patKey>.

Use the L<gitFolder|/gitFolder> parameter to specify the folder to start the list from, by default, the listing will start at the root folder of your repository.

Use the L<nonRecursive|/nonRecursive> option if you require only the files in the start folder as otherwise all the folders in the start folder will be listed as well which might take some time.

If the list operation is successful, L<failed|/failed> is set to false and L<fileList|/fileList> is set to refer to an array of the file names found.

If the list operation fails then L<failed|/failed> is set to true and L<fileList|/fileList> is set to refer to an empty array.

Returns the list of file names found or empty list if no files were found.

     Parameter  Description    
  1  $gitHub    GitHub object  

=head2 read($$)

Read data from a file on GitHub.

Required parameters: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> = the file to read.

Optional parameters: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.

If the read operation is successful, L<failed|/failed> is set to false and L<readData|/readData> is set to the data read from the file.

If the read operation fails then L<failed|/failed> is set to true and L<readData|/readData> is set to B<undef>.

Returns the data read or B<undef> if no file was found.

     Parameter  Description                   
  1  $gitHub    GitHub object                 
  2  $noLog     Whether to log errors or not  

=head2 write($$)

Write data into a GitHub file, creating the file if it is not already present.

Required parameters: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, , L<gitFile|/gitFile> = the file to be written to.

Optional parameters: L<refOrBranch|/refOrBranch>.

If the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.

     Parameter  Description         
  1  $gitHub    GitHub object       
  2  $data      Data to be written  

=head2 copy($$)

Copy a source file from one location to another target location in your GitHub repository, overwriting the target file if it already exists.

Required parameters: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be copied.

Optional parameters: L<refOrBranch|/refOrBranch>.

If the write operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns B<updated> if the write updated the file, B<created> if the write created the file else B<undef> if the write failed.

     Parameter  Description                         
  1  $gitHub    GitHub object                       
  2  $target    The name of the file to be created  

=head2 exists($)

Test whether a file exists on GitHub or not and returns an object including the B<sha> and B<size> fields if it does else undef.

Required parameters: L<userid|/userid>, L<repository|/repository>, L<gitFile|/gitFile> file to test.

Optional parameters: L<refOrBranch|/refOrBranch>, L<patKey|/patKey>.

     Parameter  Description    
  1  $gitHub    GitHub object  

=head2 rename($$)

Rename a source file on GitHub if the target file name is not already in use.

Required parameters: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be renamed.

Optional parameters: L<refOrBranch|/refOrBranch>.

Returns the new name of the file B<renamed> if the rename was successful else B<undef> if the rename failed.

     Parameter  Description               
  1  $gitHub    GitHub object             
  2  $target    The new name of the file  

=head2 delete($)

Delete a file from GitHub.

Required parameters: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>, L<gitFile|/gitFile> = the file to be deleted.

Optional parameters: L<refOrBranch|/refOrBranch>.

If the delete operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the delete was successful else false.

     Parameter  Description    
  1  $gitHub    GitHub object  

=head2 listWebHooks($)

List web hooks.

Required: L<userid|/userid>, L<repository|/repository>, L<patKey|/patKey>. 

If the list operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the list  operation was successful else false.

     Parameter  Description    
  1  $gitHub    GitHub object  

=head2 createPushWebHook($)

Create a web hook.

Required: L<userid|/userid>, L<repository|/repository>, L<url|/url>, L<patKey|/patKey>.

Optional: L<secret|/secret>.

If the create operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the web hook was created successfully else false.

     Parameter  Description    
  1  $gitHub    GitHub object  

=head2 createIssue($)

Create an issue.

Required: L<userid|/userid>, L<repository|/repository>, L<body|/body>, L<title|/title>.

If the operation is successful, L<failed|/failed> is set to false otherwise it is set to true.

Returns true if the issue was created successfully else false.

     Parameter  Description    
  1  $gitHub    GitHub object  

=head2 savePersonalAccessToken($)

Save the personal access token by userid in folder L<personalAccessTokenFolder()|/personalAccessTokenFolder>.

     Parameter  Description    
  1  $gitHub    GitHub object  

=head2 loadPersonalAccessToken($)

Load the personal access token by userid from folder L<personalAccessTokenFolder()|/personalAccessTokenFolder>.

     Parameter  Description    
  1  $gitHub    GitHub object  


=head1 Index


1 L<body|/body>

2 L<branch|/branch>

3 L<copy|/copy>

4 L<createIssue|/createIssue>

5 L<createPushWebHook|/createPushWebHook>

6 L<delete|/delete>

7 L<exists|/exists>

8 L<failed|/failed>

9 L<fileList|/fileList>

10 L<gitFile|/gitFile>

11 L<gitFolder|/gitFolder>

12 L<list|/list>

13 L<listWebHooks|/listWebHooks>

14 L<loadPersonalAccessToken|/loadPersonalAccessToken>

15 L<logFile|/logFile>

16 L<message|/message>

17 L<new|/new>

18 L<nonRecursive|/nonRecursive>

19 L<personalAccessToken|/personalAccessToken>

20 L<personalAccessTokenFolder|/personalAccessTokenFolder>

21 L<read|/read>

22 L<readData|/readData>

23 L<rename|/rename>

24 L<repository|/repository>

25 L<response|/response>

26 L<savePersonalAccessToken|/savePersonalAccessToken>

27 L<secret|/secret>

28 L<title|/title>

29 L<userid|/userid>

30 L<utf8|/utf8>

31 L<webHookUrl|/webHookUrl>

32 L<write|/write>

33 L<writeData|/writeData>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install GitHub::Crud

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

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
#podDocumentation
__DATA__
use Test::More tests => 1;

ok qm(qq('"\ abc)) eq q(\'\"%20abc);
