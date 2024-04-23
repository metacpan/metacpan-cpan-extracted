FROM centos:7

ENV TZ="America/Chicago"
RUN yum update -y
RUN yum install which -y
RUN yum install perl-core -y
RUN yum install gcc -y
RUN yum install make -y
RUN NONINTERACTIVE=1 bash -c "curl -L https://cpanmin.us | perl - App::cpanminus"
RUN cpanm JSON::Path
CMD perl -MJSON::Path -e 'print "JSON::Path v" . $JSON::Path::VERSION . "\n";'
