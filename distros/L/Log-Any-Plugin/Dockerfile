FROM perl:5.24

RUN cpanm -q -n App::cpm
RUN cpm install -g Dist::Zilla

WORKDIR /build
RUN git clone https://github.com/sdt/Log-Any-Plugin.git /build

RUN cpm install -g $( dzil authordeps --missing )
RUN cpm install -g $( dzil listdeps --develop --missing )
