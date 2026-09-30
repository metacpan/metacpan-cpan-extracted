* cpanm PPI::App::ppi_version
* ppi_version change $old_version $new_version
* git grep $old_version, update anything remaining
* update Changes file with a summary of what's been done for this release
* perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/Google/RestApi.pm > README.md
* perl Makefile.PL
* make manifest
* make distcheck to check manifest
* git commit -a
* git push
* git tag $new_version
* git push origin $new_version
* ensure git workflow passes on configured perl releases. the repo is public, so
  this needs no `gh auth` -- query the api directly:
    curl -s "https://api.github.com/repos/mvsjes2/p5-google-restapi/actions/runs?per_page=5" \
      | python3 -c "import sys,json;[print(r['created_at'],r['head_branch'],r['head_sha'][:8],r['conclusion'],r['name']) for r in json.load(sys.stdin)['workflow_runs']]"
  then the per-perl-version jobs for the run id of interest:
    curl -s "https://api.github.com/repos/mvsjes2/p5-google-restapi/actions/runs/$run_id/jobs" \
      | python3 -c "import sys,json;[print(j['conclusion'],j['name']) for j in json.load(sys.stdin)['jobs']]"
* make
* make test
* make dist
* cpanm Google-RestApi-$new_version.tar.gz
* cpan-upload Google-RestApi-${new_version}.tar.gz --user $user
* make clean
* rm Google-RestApi-${new_version}.tar.gz
