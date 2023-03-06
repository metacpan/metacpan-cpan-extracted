#!/bin/bash

export ETHEREUM_VERSION=1.10.26-e5eb32ac
export ETHEREUM_URL="https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-$ETHEREUM_VERSION.tar.gz"
export RUNNABLE_FILES=/usr/local
export NODE=geth

mkdir $NODE && wget -qO- $ETHEREUM_URL | tar xvz -C $NODE --strip-components 1
cp $NODE/$NODE /usr/local

cat > config/geth_script.js <<'EOF'
console.log(eth.sendTransaction({from:eth.coinbase, to:eth.accounts[0], value: web3.toWei(100, "ether")}));
 var block = eth.getBlock("latest");
while(block.gasLimit < 7000000) {
        console.log(eth.sendTransaction({from:eth.coinbase, to:eth.accounts[0], value: web3.toWei(1, "ether")}));
        block = eth.getBlock("latest");
}
EOF

$RUNNABLE_FILES/$NODE --dev --datadir="/tmp/.$NODE" --exec "loadScript('config/geth_script.js');" console
echo "middle of script";
nohup $RUNNABLE_FILES/$NODE --dev --datadir="/tmp/.$NODE" --mine --http --http.api admin,db,eth,debug,miner,net,shh,txpool,personal,web3  &

