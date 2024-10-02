class NodejsStringBuilder {

    constructor() {
        this.string = "";
    }

    string;

    append(string) {
        this.string += string;
    }

    getString() {
        return this.string;
    }
}

module.exports = NodejsStringBuilder