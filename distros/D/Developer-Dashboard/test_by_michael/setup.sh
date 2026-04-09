#!/bin/bash
   docker compose up -d \
&& docker compose exec app dashboard auth add-user mv 12345yes \
&& docker compose exec app mkdir -p /root/.developer-dashboard/dashboards/{public/js,nav} \
&& docker compose exec -w /root/.developer-dashboard/dashboards/public/js app bash -c 'curl https://code.jquery.com/jquery-4.0.0.min.js > jq.js' \
&& docker compose cp config.json app:/root/.developer-dashboard/config/config.json \
&& docker compose cp index.bookmark app:/root/.developer-dashboard/dashboards/index \
&& docker compose cp test.bookmark app:/root/.developer-dashboard/dashboards/test \
&& docker compose cp test2.bookmark app:/root/.developer-dashboard/dashboards/test2 \
&& docker compose cp nav/home.tt app:/root/.developer-dashboard/dashboards/nav/home.tt \
&& docker compose cp nav/test.tt app:/root/.developer-dashboard/dashboards/nav/test.tt \
&& docker compose exec -w /root/.developer-dashboard app dashboard init \
&& docker compose exec -w /root/.developer-dashboard app bash
