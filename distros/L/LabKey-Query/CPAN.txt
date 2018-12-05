# work on project and test locally:
perl Build.PL && ./Build && ./Build test


# Preparing module for CPAN:
- generate 'Build' script
    > perl Build.PL

- edit MANIFEST.SKIP if needed, add #!include_default to top
    > vi MANIFEST.SKIP
    > ./Build manifest

- bump version number -- Build.PL uses dist_version_from to find it
    > vi lib/LabKey/Query.pm

- update Changes file
    > vi Changes

- clean up 'Build' and distriction artifacts
    > ./Build distclean

- generate README.pod for nice viewing on github
    > podselect lib/LabKey/Query.pm > README.pod

- generate metadata files and dist (META.yml, META.json, LICENSE, LabKey-Query-0.00.tar.gz)
    > ./Build dist


# Push changes
    > git commit
    > git tag v<version>  # e.g. v1.06
    > git push --tags -u origin master


# upload the distro using CPAN::Uploader
    > cpan-upload LabKey-Query-v<version>.tar.gz --user labkey
