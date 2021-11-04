
# Dist::Zilla gadgets (plugins, ...) of interest

[TAU]@[2021-10-11]: Note that this list is very much INCOMPLETE, because it does not include components that I am already using and/or am familiar with!


## Picks (DZIL or otherwise)

### Non-dzil picks (but still related to AUTHORING)

* [Perl::PrereqScanner::Scanner::Hint - Plugin for Perl::PrereqScanner looking for ## REQUIRE: comments](https://metacpan.org/pod/Perl::PrereqScanner::Scanner::Hint)
* [Version::Dotted - Bump a dotted version, check if version is trial](https://metacpan.org/pod/Version::Dotted)  (supports: Odd/even and semantic schemes)


### DZIL Plugin picks (EXCEPT checks/tests or versioning)


* [Dist::Zilla::Plugin::AppendExternalData - Append data to gathered files](https://metacpan.org/pod/Dist::Zilla::Plugin::AppendExternalData)
* [Dist::Zilla::Plugin::BuildFile - build files by running an external command](https://metacpan.org/pod/Dist::Zilla::Plugin::BuildFile)
* [Dist::Zilla::Plugin::Code - dynamically create plugins from a bundle](https://metacpan.org/pod/Dist::Zilla::Plugin::Code)
* [Dist::Zilla::Plugin::Doppelgaenger - Creates an evil twin of a CPAN distribution](https://metacpan.org/pod/Dist::Zilla::Plugin::Doppelgaenger)
* [Dist::Zilla::Plugin::PrecomputeVariable - Precompute variable values during building](https://metacpan.org/pod/Dist::Zilla::Plugin::PrecomputeVariable)
* [Dist::Zilla::Plugin::ShareEmbed - Embed share files to .pm file - metacpan.org](https://metacpan.org/pod/Dist::Zilla::Plugin::ShareEmbed)
* [Dist::Zilla::Plugin::Substitute - Substitutions for files in dzil - metacpan.org](https://metacpan.org/pod/Dist::Zilla::Plugin::Substitute)
* [Dist::Zilla::Plugin::Templates - Treat source files as templates](https://metacpan.org/pod/Dist::Zilla::Plugin::Templates)


### DZIL Plugin picks (VERSIONING)

See: [Version numbers should be boring](https://xdg.me/version-numbers-should-be-boring/)

* [Dist::Zilla::Plugin::Author::VDB::Version::Read - Read version from a file](https://metacpan.org/pod/Dist::Zilla::Plugin::Author::VDB::Version::Read)
* [Dist::Zilla::Plugin::Author::VDB::Version::Bump - Bump version after release](https://metacpan.org/pod/Dist::Zilla::Plugin::Author::VDB::Version::Bump)
* [Dist::Zilla::Plugin::NextVersion::Semantic - update the next version, semantic-wise](https://metacpan.org/pod/Dist::Zilla::Plugin::NextVersion::Semantic)
* [Dist::Zilla::Plugin::StaticVersion - Specify version number manually, using a plugin](https://metacpan.org/pod/Dist::Zilla::Plugin::StaticVersion)


### DZIL Plugin picks (CHECKS & TESTS)

* [Dist::Zilla::Plugin::CheckVersionIncrement - Prevent a release unless the version number is incremented](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckVersionIncrement)
* [Dist::Zilla::Plugin::ConsistentVersionTest - Adds a release test to ensure that all modules have the same $VERSION](https://metacpan.org/pod/Dist::Zilla::Plugin::ConsistentVersionTest)



### DZIL PluginBundle picks

* [Dist::Zilla::PluginBundle::DAGOLDEN - Dist::Zilla configuration the way DAGOLDEN does it](https://metacpan.org/pod/Dist::Zilla::PluginBundle::DAGOLDEN)
* [Dist::Zilla::PluginBundle::DROLSKY - DROLSKY's plugin bundle](https://metacpan.org/pod/Dist::Zilla::PluginBundle::DROLSKY)
* [Dist::Zilla::PluginBundle::Author::ETHER - A plugin bundle for distributions built by ETHER](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Author::ETHER)
* [Dist::Zilla::PluginBundle::Author::KENTNL - BeLike::KENTNL when you build your distributions.](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Author::KENTNL)
* [Dist::Zilla::PluginBundle::Author::VDB - VDB's plugin bundle](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Author::VDB)


## Other DZIL Plugins that might be interesting

* [Dist::Zilla::Plugin::AddFile::FromFS - Add file from filesystem](https://metacpan.org/pod/Dist::Zilla::Plugin::AddFile::FromFS)
* [Dist::Zilla::Plugin::Alt - Create Alt distributions with Dist::Zilla](https://metacpan.org/pod/Dist::Zilla::Plugin::Alt)
* [Dist::Zilla::Plugin::AppendExternalData - Append data to gathered files](https://metacpan.org/pod/Dist::Zilla::Plugin::AppendExternalData)
* [Dist::Zilla::Plugin::Author::KENTNL::CONTRIBUTING - Generates a CONTRIBUTING file for KENTNL's distributions.](https://metacpan.org/pod/Dist::Zilla::Plugin::Author::KENTNL::CONTRIBUTING)
* [Dist::Zilla::Plugin::AuthorityFromModule - (DEPRECATED) Add metadata to your distribution indicating what module to copy PAUSE permissions from](https://metacpan.org/pod/Dist::Zilla::Plugin::AuthorityFromModule)
* [Dist::Zilla::Plugin::AutoMetaResources - Automagical MetaResources](https://metacpan.org/pod/Dist::Zilla::Plugin::AutoMetaResources)
* [Dist::Zilla::Plugin::AutoMetaResourcesPrefixed](https://metacpan.org/pod/Dist::Zilla::Plugin::AutoMetaResourcesPrefixed)
* [Dist::Zilla::Plugin::AutoPrereqsFast - Automatically extract prereqs from your modules, but faster](https://metacpan.org/pod/Dist::Zilla::Plugin::AutoPrereqsFast)
* [Dist::Zilla::Plugin::BuildFile - build files by running an external command](https://metacpan.org/pod/Dist::Zilla::Plugin::BuildFile)
* [Dist::Zilla::Plugin::ChangesFromYaml - convert Changes from YAML to CPAN::Changes::Spec format](https://metacpan.org/pod/Dist::Zilla::Plugin::ChangesFromYaml)
* [Dist::Zilla::Plugin::CheckForUnwantedFiles - Check for unwanted files](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckForUnwantedFiles)
* [Dist::Zilla::Plugin::CheckIssues - Retrieve count of outstanding RT and github issues for your distribution](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckIssues)
* [Dist::Zilla::Plugin::CheckMetaResources - Ensure META includes resources](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckMetaResources)
* [Dist::Zilla::Plugin::CheckPrereqsIndexed - prevent a release if you have prereqs not found on CPAN](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckPrereqsIndexed)
* [Dist::Zilla::Plugin::CheckSelfDependency - Check if your distribution declares a dependency on itself](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckSelfDependency)
* [Dist::Zilla::Plugin::CheckStrictVersion - BeforeRelease plugin to check for a strict version number](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckStrictVersion)
* [Dist::Zilla::Plugin::CheckVersionIncrement - Prevent a release unless the version number is incremented](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckVersionIncrement)
* [Dist::Zilla::Plugin::Clean - Clean after release](https://metacpan.org/pod/Dist::Zilla::Plugin::Clean)
* [Dist::Zilla::Plugin::CoalescePod - merge .pod files into their .pm counterparts](https://metacpan.org/pod/Dist::Zilla::Plugin::CoalescePod)
* [Dist::Zilla::Plugin::Code - dynamically create plugins from a bundle](https://metacpan.org/pod/Dist::Zilla::Plugin::Code)
* [Dist::Zilla::Plugin::CommentOut - Comment out code in your scripts and modules](https://metacpan.org/pod/Dist::Zilla::Plugin::CommentOut)
* [Dist::Zilla::Plugin::Conflicts - Declare conflicts for your distro](https://metacpan.org/pod/Dist::Zilla::Plugin::Conflicts)
* [Dist::Zilla::Plugin::ConsistentVersionTest - Adds a release test to ensure that all modules have the same $VERSION](https://metacpan.org/pod/Dist::Zilla::Plugin::ConsistentVersionTest)
* [Dist::Zilla::Plugin::ContributorsFile - add a file listing all contributors](https://metacpan.org/pod/Dist::Zilla::Plugin::ContributorsFile)
* [Dist::Zilla::Plugin::ContributorsFromGit - Populate your 'CONTRIBUTORS' POD from the list of git authors](https://metacpan.org/pod/Dist::Zilla::Plugin::ContributorsFromGit)
* [Dist::Zilla::Plugin::Control::Debian - Add a debian/control file to your distribution](https://metacpan.org/pod/Dist::Zilla::Plugin::Control::Debian)
* [Dist::Zilla::Plugin::CopyFilesFromBuild::Filtered - Copy files from build directory, but filter out lines](https://metacpan.org/pod/Dist::Zilla::Plugin::CopyFilesFromBuild::Filtered)
* [Dist::Zilla::Plugin::CopyFilesFromRelease - Copy files from a release (for SCM inclusion, etc.)](https://metacpan.org/pod/Dist::Zilla::Plugin::CopyFilesFromRelease)
* [Dist::Zilla::Plugin::CopyrightYearFromGit - Set copyright year from git](https://metacpan.org/pod/Dist::Zilla::Plugin::CopyrightYearFromGit)
* [Dist::Zilla::Plugin::CopyTo - Copy to other places plugin for Dist::Zilla](https://metacpan.org/pod/Dist::Zilla::Plugin::CopyTo)
* [Dist::Zilla::Plugin::Doppelgaenger - Creates an evil twin of a CPAN distribution](https://metacpan.org/pod/Dist::Zilla::Plugin::Doppelgaenger)
* [Dist::Zilla::Plugin::Dpkg - Generate Dpkg files for your perl module](https://metacpan.org/pod/Dist::Zilla::Plugin::Dpkg)
* [Dist::Zilla::Plugin::EnsureChangesHasContent - Checks Changes for content using CPAN::Changes](https://metacpan.org/pod/Dist::Zilla::Plugin::EnsureChangesHasContent)
* [Dist::Zilla::Plugin::EnsurePrereqsInstalled - Ensure at build time that all prereqs, including developer, are satisfied](https://metacpan.org/pod/Dist::Zilla::Plugin::EnsurePrereqsInstalled)
* [Dist::Zilla::Plugin::FileKeywords - expand $Keywords$ in your files.](https://metacpan.org/pod/Dist::Zilla::Plugin::FileKeywords)
* [Dist::Zilla::Plugin::FindDirByRegex - A regex-based FileFinder plugin](https://metacpan.org/pod/Dist::Zilla::Plugin::FindDirByRegex)
* [Dist::Zilla::Plugin::GenShellCompletion - Generate shell completion scripts when distribution is installed](https://metacpan.org/pod/Dist::Zilla::Plugin::GenShellCompletion)
* [Dist::Zilla::Plugin::Git::NextVersion::Sanitized - Sanitize versions handed to you by Git::NextVersion](https://metacpan.org/pod/Dist::Zilla::Plugin::Git::NextVersion::Sanitized)
* [Dist::Zilla::Plugin::Hook - Write Dist::Zilla plugin directly in dist.ini](https://metacpan.org/pod/Dist::Zilla::Plugin::Hook)
* [Dist::Zilla::Plugin::InlineModule - Dist::Zilla Plugin for Inline::Module](https://metacpan.org/dist/Dist-Zilla-Plugin-InlineModule/view/lib/Dist/Zilla/Plugin/InlineModule.pod)
* [Dist::Zilla::Plugin::InsertBlock - Insert a block of text from another file](https://metacpan.org/pod/Dist::Zilla::Plugin::InsertBlock)
* [Dist::Zilla::Plugin::InsertCodeOutput - Insert the output of Perl code into your POD](https://metacpan.org/pod/Dist::Zilla::Plugin::InsertCodeOutput)
* [Dist::Zilla::Plugin::InsertCopyright - Insert copyright statement into source code files](https://metacpan.org/pod/Dist::Zilla::Plugin::InsertCopyright)
* [Dist::Zilla::Plugin::InsertExample - Insert example into your POD from a file](https://metacpan.org/pod/Dist::Zilla::Plugin::InsertExample)
* [Dist::Zilla::Plugin::InstallRelease - installs your dist after releasing](https://metacpan.org/pod/Dist::Zilla::Plugin::InstallRelease)
* [Dist::Zilla::Plugin::Keywords - Add keywords to metadata in your distribution](https://metacpan.org/pod/Dist::Zilla::Plugin::Keywords)
* [Dist::Zilla::Plugin::LatestPrereqs - adjust prereqs to use latest version available](https://metacpan.org/pod/Dist::Zilla::Plugin::LatestPrereqs)
* [Dist::Zilla::Plugin::MakeMaker::Awesome - A more awesome MakeMaker plugin for Dist::Zilla](https://metacpan.org/pod/Dist::Zilla::Plugin::MakeMaker::Awesome)
* [Dist::Zilla::Plugin::MakeMaker::Highlander - There can be only one](https://metacpan.org/pod/Dist::Zilla::Plugin::MakeMaker::Highlander)
* [Dist::Zilla::Plugin::Manifest::Read - Read annotated source manifest](https://metacpan.org/pod/Dist::Zilla::Plugin::Manifest::Read)
* [Dist::Zilla::Plugin::Manifest::Write - Have annotated distribution manifest](https://metacpan.org/pod/Dist::Zilla::Plugin::Manifest::Write)
* [Dist::Zilla::Plugin::ManifestInRoot - Puts the MANIFEST file in the project root](https://metacpan.org/pod/Dist::Zilla::Plugin::ManifestInRoot)
* [Dist::Zilla::Plugin::MatchManifest - Ensure that MANIFEST is correct](https://metacpan.org/pod/Dist::Zilla::Plugin::MatchManifest)
* [Dist::Zilla::Plugin::Metadata - Add arbitrary keys to distmeta](https://metacpan.org/pod/Dist::Zilla::Plugin::Metadata)
* [Dist::Zilla::Plugin::MinimumVersionTests - Release tests for minimum required versions](https://metacpan.org/pod/Dist::Zilla::Plugin::MinimumVersionTests)
* [Dist::Zilla::Plugin::Munge::Whitespace - Strip superfluous spaces from pesky files.](https://metacpan.org/pod/Dist::Zilla::Plugin::Munge::Whitespace)
* [Dist::Zilla::Plugin::NextRelease::Grouped - Simplify usage of a grouped changelog](https://metacpan.org/pod/Dist::Zilla::Plugin::NextRelease::Grouped)
* [Dist::Zilla::Plugin::NextVersion::Semantic - update the next version, semantic-wise](https://metacpan.org/pod/Dist::Zilla::Plugin::NextVersion::Semantic)
* [Dist::Zilla::Plugin::OurDist - Add a $DIST to your packages (no line insertion)](https://metacpan.org/pod/Dist::Zilla::Plugin::OurDist)
* [Dist::Zilla::Plugin::PerlStripper - Strip your modules/scripts with Perl::Stripper](https://metacpan.org/pod/Dist::Zilla::Plugin::PerlStripper)
* [Dist::Zilla::Plugin::PkgAuthority - Add a $AUTHORITY to your packages.](https://metacpan.org/pod/Dist::Zilla::Plugin::PkgAuthority)
* [Dist::Zilla::Plugin::PodInherit - use Pod::Inherit to provide INHERITED METHODS sections in POD](https://metacpan.org/dist/Dist-Zilla-Plugin-PodInherit/view/lib/Dist/Zilla/Plugin/PodInherit.pod)
* [Dist::Zilla::Plugin::PodnameFromFilename - Fill out # PODNAME from filename](https://metacpan.org/pod/Dist::Zilla::Plugin::PodnameFromFilename)
* [Dist::Zilla::Plugin::PrecomputeVariable - Precompute variable values during building](https://metacpan.org/pod/Dist::Zilla::Plugin::PrecomputeVariable)
* [Dist::Zilla::Plugin::Prereqs::DarkPAN - Depend on things from arbitrary places-not-CPAN](https://metacpan.org/pod/Dist::Zilla::Plugin::Prereqs::DarkPAN)
* [Dist::Zilla::Plugin::Prereqs::Floor - Dist::Zilla plugin to set a minimum allowed version for prerequisites](https://metacpan.org/pod/Dist::Zilla::Plugin::Prereqs::Floor)
* [Dist::Zilla::Plugin::Prereqs::Plugins - Add all Dist::Zilla plugins presently in use as prerequisites.](https://metacpan.org/pod/Dist::Zilla::Plugin::Prereqs::Plugins)
* [Dist::Zilla::Plugin::Prereqs::SetMinimumVersion::FromPmVersions - Set minimum version of prereqs from pmversions.ini](https://metacpan.org/pod/Dist::Zilla::Plugin::Prereqs::SetMinimumVersion::FromPmVersions)
* [Dist::Zilla::Plugin::RemovePhasedPrereqs - Remove gathered prereqs from particular phases](https://metacpan.org/pod/Dist::Zilla::Plugin::RemovePhasedPrereqs)
* [Dist::Zilla::Plugin::RemovePrereqsMatching - A more flexible prereq remover](https://metacpan.org/pod/Dist::Zilla::Plugin::RemovePrereqsMatching)
* [Dist::Zilla::Plugin::ReportPhase - Report whats going on.](https://metacpan.org/pod/Dist::Zilla::Plugin::ReportPhase)
* [Dist::Zilla::Plugin::ReversionAfterRelease - Bump and reversion after distribution release](https://metacpan.org/pod/Dist::Zilla::Plugin::ReversionAfterRelease)
* [Dist::Zilla::Plugin::ReversionOnRelease - Bump and reversion $VERSION on release](https://metacpan.org/pod/Dist::Zilla::Plugin::ReversionOnRelease)
* [Dist::Zilla::Plugin::RewriteVersion - Get and/or rewrite module versions to match distribution version](https://metacpan.org/pod/Dist::Zilla::Plugin::RewriteVersion)
* [Dist::Zilla::Plugin::Run - Run external commands and code at specific phases of Dist::Zilla](https://metacpan.org/pod/Dist::Zilla::Plugin::Run)
* [Dist::Zilla::Plugin::SchwartzRatio - display the Schwartz ratio of the distribution upon release](https://metacpan.org/pod/Dist::Zilla::Plugin::SchwartzRatio)
* [Dist::Zilla::Plugin::SetScriptShebang - Set script shebang to #!perl](https://metacpan.org/pod/Dist::Zilla::Plugin::SetScriptShebang)
* [Dist::Zilla::Plugin::ShareEmbed - Embed share files to .pm file](https://metacpan.org/pod/Dist::Zilla::Plugin::ShareEmbed)
* [Dist::Zilla::Plugin::SpellingCommonMistakesTests - Release tests for common POD spelling mistakes](https://metacpan.org/pod/Dist::Zilla::Plugin::SpellingCommonMistakesTests)
* [Dist::Zilla::Plugin::StaticVersion - Specify version number manually, using a plugin](https://metacpan.org/pod/Dist::Zilla::Plugin::StaticVersion)
* [Dist::Zilla::Plugin::Substitute - Substitutions for files in dzil](https://metacpan.org/pod/Dist::Zilla::Plugin::Substitute)
* [Dist::Zilla::Plugin::Test::CheckDeps - Check for presence of dependencies](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::CheckDeps)
* [Dist::Zilla::Plugin::Test::EOF - Check that all files in the projects end correctly](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::EOF)
* [Dist::Zilla::Plugin::Test::LocalBrew - Verify that your distribution tests well in a fresh perlbrew](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::LocalBrew)
* [Dist::Zilla::Plugin::Test::Perl::Critic::Freenode - Tests to check your code against policies inspired by #perl on Freenode](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::Perl::Critic::Freenode)
* [Dist::Zilla::Plugin::Test::Pod::Coverage::Configurable - dzil pod coverage tests with configurable parameters](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::Pod::Coverage::Configurable)
* [Dist::Zilla::Plugin::Test::ProveRdeps - Add release test to run 'prove' on distributions that depend on us](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::ProveRdeps)
* [Dist::Zilla::Plugin::Test::TidyAll - Adds a tidyall test to your distro](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::TidyAll)
* [Dist::Zilla::Plugin::Test::TrailingSpace - test for trailing whitespace in files.](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::TrailingSpace)
* [Dist::Zilla::Plugin::TidyAll - Apply tidyall to files in Dist::Zilla](https://metacpan.org/pod/Dist::Zilla::Plugin::TidyAll)
* [Dist::Zilla::Plugin::TrialVersionComment - Add a "# TRIAL" comment after your version declaration in trial releases](https://metacpan.org/pod/Dist::Zilla::Plugin::TrialVersionComment)
* [Dist::Zilla::Plugin::UploadToStratopan - Automate Stratopan releases with Dist::Zilla](https://metacpan.org/pod/Dist::Zilla::Plugin::UploadToStratopan)
* [Dist::Zilla::Plugin::VerifyPhases - Compare data and files at different phases of the distribution build process](https://metacpan.org/pod/Dist::Zilla::Plugin::VerifyPhases)
* [Dist::Zilla::Plugin::VersionFromMainModule - Set the distribution version from your main module's $VERSION](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromMainModule)
* [Dist::Zilla::Plugin::VersionFromScript - run command line script to provide version number](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromScript)
* [Dist::Zilla::Plugin::WriteVersion](https://metacpan.org/pod/Dist::Zilla::Plugin::WriteVersion)


## PluginBundles (generic)

* [Dist::Zilla::Role::PluginBundle::Airplane - A role for building packages with Dist::Zilla in an airplane](https://metacpan.org/pod/Dist::Zilla::Role::PluginBundle::Airplane)
* [Dist::Zilla::Role::PluginBundle::Merged - Mindnumbingly easy way to create a PluginBundle](https://metacpan.org/pod/Dist::Zilla::Role::PluginBundle::Merged)


## Author specific stuff

* [Dist::Zilla::Plugin::MAXMIND::TidyAll - Creates default tidyall.ini, perltidyrc, and perlcriticrc files if they don't yet exist](https://metacpan.org/dist/Dist-Zilla-PluginBundle-MAXMIND/view/lib/Dist/Zilla/Plugin/MAXMIND/TidyAll.pm)