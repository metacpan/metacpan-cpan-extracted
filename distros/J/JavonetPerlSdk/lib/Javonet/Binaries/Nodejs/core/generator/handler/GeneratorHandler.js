const NodejsStringBuilder = require("../internal/NodejsStringBuilder");
const Handlers = require("./Handlers");
const fs = require('fs');

class GeneratorHandler {

    generate(command, file_path) {

        let generator_handlers = new Handlers()
        let loadedClassFiles = []
        for (let i = 0; i < command.payload.length; i++) {
            let existing_string_builder = new NodejsStringBuilder();
            let payloadItem = command.payload[i]
            generator_handlers.GENERATOR_HANDLER[command.payload[i].commandType].generate_code(existing_string_builder, command, command.payload[i], generator_handlers)
            this.generate_class_file(existing_string_builder, command.payload[i].payload[0], file_path)
            loadedClassFiles.push(this.generate_class_file(existing_string_builder, payloadItem.payload[0],file_path))
        }
        return loadedClassFiles
    }


    generate_class_file(existing_string_builder, class_file_name, file_path) {
        fs.writeFile(file_path + "\\" + class_file_name.substring(class_file_name.lastIndexOf(".") + 1) + '.js', existing_string_builder.getString(), function (err) {
            if (err) throw err;
        });
        return existing_string_builder.getString();
    }
}

module.exports = GeneratorHandler